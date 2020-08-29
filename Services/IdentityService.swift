// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class IdentityService {
    @Published private(set) var identity: Identity
    let observationErrors: AnyPublisher<Error, Never>

    private let identityDatabase: IdentityDatabase
    private let contentDatabase: ContentDatabase
    private let environment: AppEnvironment
    private let networkClient: MastodonClient
    private let secretsService: SecretsService
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
        secretsService = SecretsService(
            identityID: identityID,
            keychainService: environment.keychainServiceType)
        networkClient = MastodonClient(environment: environment)
        networkClient.instanceURL = identity.url
        networkClient.accessToken = try? secretsService.item(.accessToken)

        contentDatabase = try ContentDatabase(identityID: identityID, environment: environment)

        observation.catch { [weak self] error -> Empty<Identity, Never> in
            self?.observationErrorsInput.send(error)

            return Empty()
        }
        .assign(to: &$identity)
    }
}

extension IdentityService {
    var isAuthorized: Bool { networkClient.accessToken != nil }

    func updateLastUse() -> AnyPublisher<Never, Error> {
        identityDatabase.updateLastUsedAt(identityID: identity.id)
    }

    func verifyCredentials() -> AnyPublisher<Never, Error> {
        networkClient.request(AccountEndpoint.verifyCredentials)
            .zip(Just(identity.id).first().setFailureType(to: Error.self))
            .flatMap(identityDatabase.updateAccount)
            .eraseToAnyPublisher()
    }

    func refreshServerPreferences() -> AnyPublisher<Never, Error> {
        networkClient.request(PreferencesEndpoint.preferences)
            .zip(Just(self).first().setFailureType(to: Error.self))
            .map { ($1.identity.preferences.updated(from: $0), $1.identity.id) }
            .flatMap(identityDatabase.updatePreferences)
            .eraseToAnyPublisher()
    }

    func refreshInstance() -> AnyPublisher<Never, Error> {
        networkClient.request(InstanceEndpoint.instance)
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
        networkClient.request(ListsEndpoint.lists)
            .flatMap(contentDatabase.setLists(_:))
            .eraseToAnyPublisher()
    }

    func createList(title: String) -> AnyPublisher<Never, Error> {
        networkClient.request(ListEndpoint.create(title: title))
            .flatMap(contentDatabase.createList(_:))
            .eraseToAnyPublisher()
    }

    func deleteList(id: String) -> AnyPublisher<Never, Error> {
        networkClient.request(DeletionEndpoint.list(id: id))
            .map { _ in id }
            .flatMap(contentDatabase.deleteList(id:))
            .eraseToAnyPublisher()
    }

    func listsObservation() -> AnyPublisher<[Timeline], Error> {
        contentDatabase.listsObservation()
    }

    func refreshFilters() -> AnyPublisher<Never, Error> {
        networkClient.request(FiltersEndpoint.filters)
            .flatMap(contentDatabase.setFilters(_:))
            .eraseToAnyPublisher()
    }

    func createFilter(_ filter: Filter) -> AnyPublisher<Never, Error> {
        networkClient.request(FilterEndpoint.create(phrase: filter.phrase,
                                                    context: filter.context,
                                                    irreversible: filter.irreversible,
                                                    wholeWord: filter.wholeWord,
                                                    expiresIn: filter.expiresAt))
            .flatMap(contentDatabase.createFilter(_:))
            .eraseToAnyPublisher()
    }

    func updateFilter(_ filter: Filter) -> AnyPublisher<Never, Error> {
        networkClient.request(FilterEndpoint.update(id: filter.id,
                                                    phrase: filter.phrase,
                                                    context: filter.context,
                                                    irreversible: filter.irreversible,
                                                    wholeWord: filter.wholeWord,
                                                    expiresIn: filter.expiresAt))
            .flatMap(contentDatabase.createFilter(_:))
            .eraseToAnyPublisher()
    }

    func deleteFilter(id: String) -> AnyPublisher<Never, Error> {
        networkClient.request(DeletionEndpoint.filter(id: id))
            .map { _ in id }
            .flatMap(contentDatabase.deleteFilter(id:))
            .eraseToAnyPublisher()
    }

    func filtersObservation() -> AnyPublisher<[Filter], Error> {
        contentDatabase.filtersObservation()
    }

    func updatePreferences(_ preferences: Identity.Preferences) -> AnyPublisher<Never, Error> {
        identityDatabase.updatePreferences(preferences, forIdentityID: identity.id)
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
            publicKey = try secretsService.generatePushKeyAndReturnPublicKey().base64EncodedString()
            auth = try secretsService.generatePushAuth().base64EncodedString()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        let identityID = identity.id
        let endpoint = Self.pushSubscriptionEndpointURL
            .appendingPathComponent(deviceToken)
            .appendingPathComponent(identityID.uuidString)

        return networkClient.request(
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

        return networkClient.request(PushSubscriptionEndpoint.update(alerts: alerts))
            .map { ($0.alerts, nil, identityID) }
            .flatMap(identityDatabase.updatePushSubscription(alerts:deviceToken:forIdentityID:))
            .eraseToAnyPublisher()
    }

    func service(timeline: Timeline) -> StatusListService {
        TimelineService(timeline: timeline, networkClient: networkClient, contentDatabase: contentDatabase)
    }
}

private extension IdentityService {
    #if DEBUG
    static let pushSubscriptionEndpointURL = URL(string: "https://metatext-apns.metabolist.com/push?sandbox=true")!
    #else
    static let pushSubscriptionEndpointURL = URL(string: "https://metatext-apns.metabolist.com/push")!
    #endif
}
