// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI
import Secrets

public class IdentityService {
    @Published public private(set) var identity: Identity
    public let observationErrors: AnyPublisher<Error, Never>

    private let identityDatabase: IdentityDatabase
    private let contentDatabase: ContentDatabase
    private let environment: AppEnvironment
    private let mastodonAPIClient: MastodonAPIClient
    private let secrets: Secrets
    private let observationErrorsInput = PassthroughSubject<Error, Never>()

    init(identityID: UUID,
         identityDatabase: IdentityDatabase,
         environment: AppEnvironment) throws {
        self.identityDatabase = identityDatabase
        self.environment = environment
        observationErrors = observationErrorsInput.eraseToAnyPublisher()

        let observation = identityDatabase.identityObservation(id: identityID).share()
        var initialIdentity: Identity?

        _ = observation.first().sink(
            receiveCompletion: { _ in },
            receiveValue: { initialIdentity = $0 })

        guard let identity = initialIdentity else { throw IdentityDatabaseError.identityNotFound }

        self.identity = identity
        secrets = Secrets(
            identityID: identityID,
            keychain: environment.keychain)
        mastodonAPIClient = MastodonAPIClient(session: environment.session)
        mastodonAPIClient.instanceURL = identity.url
        mastodonAPIClient.accessToken = try? secrets.getAccessToken()

        contentDatabase = try ContentDatabase(identityID: identityID,
                                              inMemory: environment.inMemoryContent,
                                              keychain: environment.keychain)

        observation.catch { [weak self] error -> Empty<Identity, Never> in
            self?.observationErrorsInput.send(error)

            return Empty()
        }
        .assign(to: &$identity)
    }
}

public extension IdentityService {
    var isAuthorized: Bool { mastodonAPIClient.accessToken != nil }

    func updateLastUse() -> AnyPublisher<Never, Error> {
        identityDatabase.updateLastUsedAt(identityID: identity.id)
    }

    func verifyCredentials() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(AccountEndpoint.verifyCredentials)
            .zip(Just(identity.id).first().setFailureType(to: Error.self))
            .flatMap(identityDatabase.updateAccount)
            .eraseToAnyPublisher()
    }

    func refreshServerPreferences() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(PreferencesEndpoint.preferences)
            .zip(Just(self).first().setFailureType(to: Error.self))
            .map { ($1.identity.preferences.updated(from: $0), $1.identity.id) }
            .flatMap(identityDatabase.updatePreferences)
            .eraseToAnyPublisher()
    }

    func refreshInstance() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(InstanceEndpoint.instance)
            .zip(Just(identity.id).first().setFailureType(to: Error.self))
            .flatMap(identityDatabase.updateInstance)
            .eraseToAnyPublisher()
    }

    func identitiesObservation() -> AnyPublisher<[Identity], Error> {
        identityDatabase.identitiesObservation()
    }

    func recentIdentitiesObservation() -> AnyPublisher<[Identity], Error> {
        identityDatabase.recentIdentitiesObservation(excluding: identity.id)
    }

    func refreshLists() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(ListsEndpoint.lists)
            .flatMap(contentDatabase.setLists(_:))
            .eraseToAnyPublisher()
    }

    func createList(title: String) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(ListEndpoint.create(title: title))
            .flatMap(contentDatabase.createList(_:))
            .eraseToAnyPublisher()
    }

    func deleteList(id: String) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(DeletionEndpoint.list(id: id))
            .map { _ in id }
            .flatMap(contentDatabase.deleteList(id:))
            .eraseToAnyPublisher()
    }

    func listsObservation() -> AnyPublisher<[Timeline], Error> {
        contentDatabase.listsObservation()
    }

    func refreshFilters() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(FiltersEndpoint.filters)
            .flatMap(contentDatabase.setFilters(_:))
            .eraseToAnyPublisher()
    }

    func createFilter(_ filter: Filter) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(FilterEndpoint.create(phrase: filter.phrase,
                                                    context: filter.context,
                                                    irreversible: filter.irreversible,
                                                    wholeWord: filter.wholeWord,
                                                    expiresIn: filter.expiresAt))
            .flatMap(contentDatabase.createFilter(_:))
            .eraseToAnyPublisher()
    }

    func updateFilter(_ filter: Filter) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(FilterEndpoint.update(id: filter.id,
                                                    phrase: filter.phrase,
                                                    context: filter.context,
                                                    irreversible: filter.irreversible,
                                                    wholeWord: filter.wholeWord,
                                                    expiresIn: filter.expiresAt))
            .flatMap(contentDatabase.createFilter(_:))
            .eraseToAnyPublisher()
    }

    func deleteFilter(id: String) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(DeletionEndpoint.filter(id: id))
            .map { _ in id }
            .flatMap(contentDatabase.deleteFilter(id:))
            .eraseToAnyPublisher()
    }

    func activeFiltersObservation(date: Date) -> AnyPublisher<[Filter], Error> {
        contentDatabase.activeFiltersObservation(date: date)
    }

    func expiredFiltersObservation(date: Date) -> AnyPublisher<[Filter], Error> {
        contentDatabase.expiredFiltersObservation(date: date)
    }

    func updatePreferences(_ preferences: Identity.Preferences) -> AnyPublisher<Never, Error> {
        identityDatabase.updatePreferences(preferences, forIdentityID: identity.id)
            .collect()
            .zip(Just(self).first().setFailureType(to: Error.self))
            .filter { $1.identity.preferences.useServerPostingReadingPreferences }
            .map { _ in () }
            .flatMap(refreshServerPreferences)
            .eraseToAnyPublisher()
    }

    func createPushSubscription(deviceToken: String, alerts: PushSubscription.Alerts) -> AnyPublisher<Never, Error> {
        let publicKey: String
        let auth: String

        do {
            publicKey = try secrets.generatePushKeyAndReturnPublicKey().base64EncodedString()
            auth = try secrets.generatePushAuth().base64EncodedString()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        let identityID = identity.id
        let endpoint = Self.pushSubscriptionEndpointURL
            .appendingPathComponent(deviceToken)
            .appendingPathComponent(identityID.uuidString)

        return mastodonAPIClient.request(
            PushSubscriptionEndpoint.create(
                endpoint: endpoint,
                publicKey: publicKey,
                auth: auth,
                alerts: alerts))
            .map { ($0.alerts, deviceToken, identityID) }
            .flatMap(identityDatabase.updatePushSubscription(alerts:deviceToken:forIdentityID:))
            .eraseToAnyPublisher()
    }

    func updatePushSubscription(alerts: PushSubscription.Alerts) -> AnyPublisher<Never, Error> {
        let identityID = identity.id

        return mastodonAPIClient.request(PushSubscriptionEndpoint.update(alerts: alerts))
            .map { ($0.alerts, nil, identityID) }
            .flatMap(identityDatabase.updatePushSubscription(alerts:deviceToken:forIdentityID:))
            .eraseToAnyPublisher()
    }

    func service(timeline: Timeline) -> StatusListService {
        StatusListService(timeline: timeline, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }
}

private extension IdentityService {
    #if DEBUG
    static let pushSubscriptionEndpointURL = URL(string: "https://metatext-apns.metabolist.com/push?sandbox=true")!
    #else
    static let pushSubscriptionEndpointURL = URL(string: "https://metatext-apns.metabolist.com/push")!
    #endif
}
