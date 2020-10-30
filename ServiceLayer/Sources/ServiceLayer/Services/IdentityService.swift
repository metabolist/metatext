// Copyright © 2020 Metabolist. All rights reserved.

import Base16
import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI
import Secrets

public struct IdentityService {
    private let id: Identity.Id
    private let identityDatabase: IdentityDatabase
    private let contentDatabase: ContentDatabase
    private let environment: AppEnvironment
    private let mastodonAPIClient: MastodonAPIClient
    private let secrets: Secrets

    init(id: Identity.Id, database: IdentityDatabase, environment: AppEnvironment) throws {
        self.id = id
        identityDatabase = database
        self.environment = environment
        secrets = Secrets(
            identityId: id,
            keychain: environment.keychain)
        mastodonAPIClient = MastodonAPIClient(session: environment.session,
                                              instanceURL: try secrets.getInstanceURL())
        mastodonAPIClient.accessToken = try? secrets.getAccessToken()

        let appPreferences = AppPreferences(environment: environment)

        contentDatabase = try ContentDatabase(
            id: id,
            useHomeTimelineLastReadId: appPreferences.homeTimelineBehavior == .rememberPosition,
            useNotificationsLastReadId: appPreferences.notificationsTabBehavior == .rememberPosition,
            inMemory: environment.inMemoryContent,
            keychain: environment.keychain)
    }
}

public extension IdentityService {
    func updateLastUse() -> AnyPublisher<Never, Error> {
        identityDatabase.updateLastUsedAt(id: id)
    }

    func verifyCredentials() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(AccountEndpoint.verifyCredentials)
            .flatMap { identityDatabase.updateAccount($0, id: id) }
            .eraseToAnyPublisher()
    }

    func refreshServerPreferences() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(PreferencesEndpoint.preferences)
            .flatMap { identityDatabase.updatePreferences($0, id: id) }
            .eraseToAnyPublisher()
    }

    func refreshInstance() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(InstanceEndpoint.instance)
            .flatMap { identityDatabase.updateInstance($0, id: id) }
            .eraseToAnyPublisher()
    }

    func confirmIdentity() -> AnyPublisher<Never, Error> {
        identityDatabase.confirmIdentity(id: id)
    }

    func identitiesPublisher() -> AnyPublisher<[Identity], Error> {
        identityDatabase.identitiesPublisher()
    }

    func recentIdentitiesPublisher() -> AnyPublisher<[Identity], Error> {
        identityDatabase.recentIdentitiesPublisher(excluding: id)
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

    func deleteList(id: List.Id) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(DeletionEndpoint.list(id: id))
            .map { _ in id }
            .flatMap(contentDatabase.deleteList(id:))
            .eraseToAnyPublisher()
    }

    func getMarker(_ markerTimeline: Marker.Timeline) -> AnyPublisher<Marker, Error> {
        mastodonAPIClient.request(MarkersEndpoint.get([markerTimeline]))
            .compactMap { $0[markerTimeline.rawValue] }
            .eraseToAnyPublisher()
    }

    func getLocalLastReadId(_ markerTimeline: Marker.Timeline) -> String? {
        contentDatabase.lastReadId(markerTimeline)
    }

    func setLastReadId(_ id: String, forMarker markerTimeline: Marker.Timeline) -> AnyPublisher<Never, Error> {
        switch AppPreferences(environment: environment).positionBehavior(markerTimeline: markerTimeline) {
        case .rememberPosition:
            return contentDatabase.setLastReadId(id, markerTimeline: markerTimeline)
        case .syncPosition:
            return mastodonAPIClient.request(MarkersEndpoint.post([markerTimeline: id]))
                .ignoreOutput()
                .eraseToAnyPublisher()
        case .newest:
            return Empty().eraseToAnyPublisher()
        }
    }

    func identityPublisher(immediate: Bool) -> AnyPublisher<Identity, Error> {
        identityDatabase.identityPublisher(id: id, immediate: immediate)
    }

    func listsPublisher() -> AnyPublisher<[Timeline], Error> {
        contentDatabase.listsPublisher()
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

    func deleteFilter(id: Filter.Id) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(DeletionEndpoint.filter(id: id))
            .flatMap { _ in contentDatabase.deleteFilter(id: id) }
            .eraseToAnyPublisher()
    }

    func activeFiltersPublisher() -> AnyPublisher<[Filter], Error> {
        contentDatabase.activeFiltersPublisher
    }

    func expiredFiltersPublisher() -> AnyPublisher<[Filter], Error> {
        contentDatabase.expiredFiltersPublisher()
    }

    func updatePreferences(_ preferences: Identity.Preferences) -> AnyPublisher<Never, Error> {
        identityDatabase.updatePreferences(preferences, id: id)
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
            .appendingPathComponent(id.uuidString)

        return mastodonAPIClient.request(
            PushSubscriptionEndpoint.create(
                endpoint: endpoint,
                publicKey: publicKey,
                auth: auth,
                alerts: alerts))
            .map { ($0.alerts, deviceToken, id) }
            .flatMap(identityDatabase.updatePushSubscription(alerts:deviceToken:id:))
            .eraseToAnyPublisher()
    }

    func updatePushSubscription(alerts: PushSubscription.Alerts) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(PushSubscriptionEndpoint.update(alerts: alerts))
            .map { ($0.alerts, nil, id) }
            .flatMap(identityDatabase.updatePushSubscription(alerts:deviceToken:id:))
            .eraseToAnyPublisher()
    }

    func service(timeline: Timeline) -> TimelineService {
        TimelineService(timeline: timeline, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func notificationsService() -> NotificationsService {
        NotificationsService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }
}

private extension IdentityService {
    #if DEBUG
    static let pushSubscriptionEndpointURL = URL(string: "https://metatext-apns.metabolist.com/push?sandbox=true")!
    #else
    static let pushSubscriptionEndpointURL = URL(string: "https://metatext-apns.metabolist.com/push")!
    #endif
}
