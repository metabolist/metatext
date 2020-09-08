// Copyright © 2020 Metabolist. All rights reserved.

import Base16
import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI
import Secrets

public struct IdentityService {
    private let identityID: UUID
    private let identityDatabase: IdentityDatabase
    private let contentDatabase: ContentDatabase
    private let environment: AppEnvironment
    private let mastodonAPIClient: MastodonAPIClient
    private let secrets: Secrets
    private let observationErrorsInput = PassthroughSubject<Error, Never>()

    init(id: UUID, database: IdentityDatabase, environment: AppEnvironment) throws {
        identityID = id
        identityDatabase = database
        self.environment = environment
        secrets = Secrets(
            identityID: id,
            keychain: environment.keychain)
        mastodonAPIClient = MastodonAPIClient(session: environment.session)
        mastodonAPIClient.instanceURL = try secrets.getInstanceURL()
        mastodonAPIClient.accessToken = try? secrets.getAccessToken()

        contentDatabase = try ContentDatabase(identityID: id,
                                              inMemory: environment.inMemoryContent,
                                              keychain: environment.keychain)
    }
}

public extension IdentityService {
    var isAuthorized: Bool { mastodonAPIClient.accessToken != nil }

    func updateLastUse() -> AnyPublisher<Never, Error> {
        identityDatabase.updateLastUsedAt(identityID: identityID)
    }

    func verifyCredentials() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(AccountEndpoint.verifyCredentials)
            .flatMap { identityDatabase.updateAccount($0, forIdentityID: identityID) }
            .eraseToAnyPublisher()
    }

    func refreshServerPreferences() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(PreferencesEndpoint.preferences)
            .flatMap { identityDatabase.updatePreferences($0, forIdentityID: identityID) }
            .eraseToAnyPublisher()
    }

    func refreshInstance() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(InstanceEndpoint.instance)
            .flatMap { identityDatabase.updateInstance($0, forIdentityID: identityID) }
            .eraseToAnyPublisher()
    }

    func identitiesObservation() -> AnyPublisher<[Identity], Error> {
        identityDatabase.identitiesObservation()
    }

    func recentIdentitiesObservation() -> AnyPublisher<[Identity], Error> {
        identityDatabase.recentIdentitiesObservation(excluding: identityID)
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

    func observation() -> AnyPublisher<Identity, Error> {
        identityDatabase.identityObservation(id: identityID)
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
            .flatMap { _ in contentDatabase.deleteFilter(id: id) }
            .eraseToAnyPublisher()
    }

    func activeFiltersObservation(date: Date) -> AnyPublisher<[Filter], Error> {
        contentDatabase.activeFiltersObservation(date: date)
    }

    func expiredFiltersObservation(date: Date) -> AnyPublisher<[Filter], Error> {
        contentDatabase.expiredFiltersObservation(date: date)
    }

    func updatePreferences(_ preferences: Identity.Preferences) -> AnyPublisher<Never, Error> {
        identityDatabase.updatePreferences(preferences, forIdentityID: identityID)
            .collect()
            .filter { _ in preferences.useServerPostingReadingPreferences }
            .flatMap { _ in refreshServerPreferences() }
            .eraseToAnyPublisher()
    }

    func createPushSubscription(deviceToken: Data, alerts: PushSubscription.Alerts) -> AnyPublisher<Never, Error> {
        let publicKey: String
        let auth: String

        do {
            publicKey = try secrets.generatePushKeyAndReturnPublicKey().base64EncodedString()
            auth = try secrets.generatePushAuth().base64EncodedString()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        let endpoint = Self.pushSubscriptionEndpointURL
            .appendingPathComponent(deviceToken.base16EncodedString())
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
        mastodonAPIClient.request(PushSubscriptionEndpoint.update(alerts: alerts))
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
