// Copyright © 2020 Metabolist. All rights reserved.

import Base16
import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI
import Secrets

public struct IdentityService {
    public let navigationService: NavigationService

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
            useHomeTimelineLastReadId: appPreferences.homeTimelineBehavior == .localRememberPosition,
            inMemory: environment.inMemoryContent,
            appGroup: AppEnvironment.appGroup,
            keychain: environment.keychain)

        navigationService = NavigationService(
            environment: environment,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
    }
}

public extension IdentityService {
    func updateLastUse() -> AnyPublisher<Never, Error> {
        identityDatabase.updateLastUsedAt(id: id)
    }

    func verifyCredentials() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(AccountEndpoint.verifyCredentials)
            .handleEvents(receiveOutput: {
                try? secrets.setAccountId($0.id)
                try? secrets.setUsername($0.username)
            })
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
            .flatMap {
                identityDatabase.updateInstance($0, id: id)
                    .merge(with: contentDatabase.insert(instance: $0))
            }
            .eraseToAnyPublisher()
    }

    func refreshEmojis() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(EmojisEndpoint.customEmojis)
            .flatMap(contentDatabase.update(emojis:))
            .eraseToAnyPublisher()
    }

    func refreshAnnouncements() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(AnnouncementsEndpoint.announcements)
            .flatMap(contentDatabase.update(announcements:))
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

    func otherAuthenticatedIdentitiesPublisher() -> AnyPublisher<[Identity], Error> {
        identityDatabase.authenticatedIdentitiesPublisher(excluding: id)
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
        mastodonAPIClient.request(EmptyEndpoint.deleteList(id: id))
            .map { _ in id }
            .flatMap(contentDatabase.deleteList(id:))
            .eraseToAnyPublisher()
    }

    func requestRelationships(ids: Set<Account.Id>) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(RelationshipsEndpoint.relationships(ids: Array(ids)))
            .flatMap(contentDatabase.insert(relationships:))
            .eraseToAnyPublisher()
    }

    func getLocalLastReadId(timeline: Timeline) -> String? {
        contentDatabase.lastReadId(timelineId: timeline.id)
    }

    func setLocalLastReadId(_ id: String, timeline: Timeline) -> AnyPublisher<Never, Error> {
        contentDatabase.setLastReadId(id, timelineId: timeline.id)
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
        mastodonAPIClient.request(EmptyEndpoint.deleteFilter(id: id))
            .flatMap { _ in contentDatabase.deleteFilter(id: id) }
            .eraseToAnyPublisher()
    }

    func activeFiltersPublisher() -> AnyPublisher<[Filter], Error> {
        contentDatabase.activeFiltersPublisher
    }

    func expiredFiltersPublisher() -> AnyPublisher<[Filter], Error> {
        contentDatabase.expiredFiltersPublisher()
    }

    func pickerEmojisPublisher() -> AnyPublisher<[Emoji], Error> {
        contentDatabase.pickerEmojisPublisher()
    }

    func updatePreferences(_ preferences: Identity.Preferences, authenticated: Bool) -> AnyPublisher<Never, Error> {
        identityDatabase.updatePreferences(preferences, id: id)
            .collect()
            .filter { _ in preferences.useServerPostingReadingPreferences && authenticated }
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

    func uploadAttachment(data: Data, mimeType: String, progress: Progress) -> AnyPublisher<Attachment, Error> {
        mastodonAPIClient.request(
            AttachmentEndpoint.create(data: data, mimeType: mimeType, description: nil, focus: nil),
            progress: progress)
    }

    func updateAttachment(id: Attachment.Id,
                          description: String,
                          focus: Attachment.Meta.Focus) -> AnyPublisher<Attachment, Error> {
        mastodonAPIClient.request(AttachmentEndpoint.update(id: id, description: description, focus: focus))
    }

    func post(statusComponents: StatusComponents) -> AnyPublisher<Status.Id, Error> {
        mastodonAPIClient.request(StatusEndpoint.post(statusComponents)).map(\.id).eraseToAnyPublisher()
    }

    func notificationService(pushNotification: PushNotification) -> AnyPublisher<NotificationService, Error> {
        mastodonAPIClient.request(NotificationEndpoint.notification(id: .init(pushNotification.notificationId)))
            .flatMap { notification in
                contentDatabase.insert(notifications: [notification])
                    .collect()
                    .map { _ in
                        NotificationService(
                            notification: notification,
                            environment: environment,
                            mastodonAPIClient: mastodonAPIClient,
                            contentDatabase: contentDatabase)
                    }
            }
            .eraseToAnyPublisher()
    }

    func service(accountList: AccountsEndpoint, titleComponents: [String]? = nil) -> AccountListService {
        AccountListService(
            endpoint: accountList,
            environment: environment,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase,
            titleComponents: titleComponents)
    }

    func exploreService() -> ExploreService {
        ExploreService(environment: environment, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func searchService() -> SearchService {
        SearchService(environment: environment, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func notificationsService(excludeTypes: Set<MastodonNotification.NotificationType>) -> NotificationsService {
        NotificationsService(excludeTypes: excludeTypes,
                             environment: environment,
                             mastodonAPIClient: mastodonAPIClient,
                             contentDatabase: contentDatabase)
    }

    func conversationsService() -> ConversationsService {
        ConversationsService(environment: environment,
                             mastodonAPIClient: mastodonAPIClient,
                             contentDatabase: contentDatabase)
    }

    func domainBlocksService() -> DomainBlocksService {
        DomainBlocksService(mastodonAPIClient: mastodonAPIClient)
    }

    func emojiPickerService() -> EmojiPickerService {
        EmojiPickerService(contentDatabase: contentDatabase)
    }
}

private extension IdentityService {
    #if DEBUG
    static let pushSubscriptionEndpointURL = URL(string: "https://metatext-apns.metabolist.org/push?sandbox=true")!
    #else
    static let pushSubscriptionEndpointURL = URL(string: "https://metatext-apns.metabolist.org/push")!
    #endif
}
