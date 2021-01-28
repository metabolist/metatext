// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import GRDB
import Keychain
import Mastodon
import Secrets

// swiftlint:disable file_length
public struct ContentDatabase {
    public let activeFiltersPublisher: AnyPublisher<[Filter], Error>

    private let id: Identity.Id
    private let databaseWriter: DatabaseWriter

    public init(id: Identity.Id,
                useHomeTimelineLastReadId: Bool,
                useNotificationsLastReadId: Bool,
                inMemory: Bool,
                appGroup: String,
                keychain: Keychain.Type) throws {
        self.id = id

        if inMemory {
            databaseWriter = DatabaseQueue()
            try Self.migrator.migrate(databaseWriter)
        } else {
            databaseWriter = try DatabasePool.withFileCoordinator(
                url: Self.fileURL(id: id, appGroup: appGroup),
                migrator: Self.migrator) {
                try Secrets.databaseKey(identityId: id, keychain: keychain)
            }
        }

        try Self.clean(
            databaseWriter,
            useHomeTimelineLastReadId: useHomeTimelineLastReadId,
            useNotificationsLastReadId: useNotificationsLastReadId)

        activeFiltersPublisher = ValueObservation.tracking {
            try Filter.filter(Filter.Columns.expiresAt == nil || Filter.Columns.expiresAt > Date()).fetchAll($0)
        }
        .removeDuplicates()
        .publisher(in: databaseWriter)
        .eraseToAnyPublisher()
    }
}

public extension ContentDatabase {
    static func delete(id: Identity.Id, appGroup: String) throws {
        try FileManager.default.removeItem(at: fileURL(id: id, appGroup: appGroup))
    }

    func insert(status: Status) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(updates: status.save)
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func insert(
        statuses: [Status],
        timeline: Timeline,
        loadMoreAndDirection: (LoadMore, LoadMore.Direction)? = nil) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            let timelineRecord = TimelineRecord(timeline: timeline)

            try timelineRecord.save($0)

            let maxIdPresent = try String.fetchOne($0, timelineRecord.statuses.select(max(StatusRecord.Columns.id)))

            for status in statuses {
                try status.save($0)

                try TimelineStatusJoin(timelineId: timeline.id, statusId: status.id).save($0)
            }

            if let maxIdPresent = maxIdPresent,
               let minIdInserted = statuses.map(\.id).min(),
               minIdInserted > maxIdPresent {
                try LoadMoreRecord(
                    timelineId: timeline.id,
                    afterStatusId: minIdInserted,
                    beforeStatusId: maxIdPresent)
                    .save($0)
            }

            guard let (loadMore, direction) = loadMoreAndDirection else { return }

            try LoadMoreRecord(
                timelineId: loadMore.timeline.id,
                afterStatusId: loadMore.afterStatusId,
                beforeStatusId: loadMore.beforeStatusId)
                .delete($0)

            switch direction {
            case .up:
                if let maxIdInserted = statuses.map(\.id).max(), maxIdInserted < loadMore.afterStatusId {
                    try LoadMoreRecord(
                        timelineId: loadMore.timeline.id,
                        afterStatusId: loadMore.afterStatusId,
                        beforeStatusId: maxIdInserted)
                        .save($0)
                }
            case .down:
                if let minIdInserted = statuses.map(\.id).min(), minIdInserted > loadMore.beforeStatusId {
                    try LoadMoreRecord(
                        timelineId: loadMore.timeline.id,
                        afterStatusId: minIdInserted,
                        beforeStatusId: loadMore.beforeStatusId)
                        .save($0)
                }
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func insert(context: Context, parentId: Status.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for (index, status) in context.ancestors.enumerated() {
                try status.save($0)
                try StatusAncestorJoin(parentId: parentId, statusId: status.id, index: index).save($0)
            }

            for (index, status) in context.descendants.enumerated() {
                try status.save($0)
                try StatusDescendantJoin(parentId: parentId, statusId: status.id, index: index).save($0)
            }

            try StatusAncestorJoin.filter(
                StatusAncestorJoin.Columns.parentId == parentId
                    && !context.ancestors.map(\.id).contains(StatusAncestorJoin.Columns.statusId))
                .deleteAll($0)

            try StatusDescendantJoin.filter(
                StatusDescendantJoin.Columns.parentId == parentId
                    && !context.descendants.map(\.id).contains(StatusDescendantJoin.Columns.statusId))
                .deleteAll($0)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func insert(pinnedStatuses: [Status], accountId: Account.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for (index, status) in pinnedStatuses.enumerated() {
                try status.save($0)
                try AccountPinnedStatusJoin(accountId: accountId, statusId: status.id, index: index).save($0)
            }

            try AccountPinnedStatusJoin.filter(
                AccountPinnedStatusJoin.Columns.accountId == accountId
                    && !pinnedStatuses.map(\.id).contains(AccountPinnedStatusJoin.Columns.statusId))
                .deleteAll($0)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func toggleShowContent(id: Status.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            if let toggle = try StatusShowContentToggle
                .filter(StatusShowContentToggle.Columns.statusId == id)
                .fetchOne($0) {
                try toggle.delete($0)
            } else {
                try StatusShowContentToggle(statusId: id).save($0)
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func toggleShowAttachments(id: Status.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            if let toggle = try StatusShowAttachmentsToggle
                .filter(StatusShowAttachmentsToggle.Columns.statusId == id)
                .fetchOne($0) {
                try toggle.delete($0)
            } else {
                try StatusShowAttachmentsToggle(statusId: id).save($0)
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func expand(ids: Set<Status.Id>) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for id in ids {
                try StatusShowContentToggle(statusId: id).save($0)
                try StatusShowAttachmentsToggle(statusId: id).save($0)
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func collapse(ids: Set<Status.Id>) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            try StatusShowContentToggle
                .filter(ids.contains(StatusShowContentToggle.Columns.statusId))
                .deleteAll($0)
            try StatusShowAttachmentsToggle
                .filter(ids.contains(StatusShowContentToggle.Columns.statusId))
                .deleteAll($0)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func update(id: Status.Id, poll: Poll) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            let data = try StatusRecord.databaseJSONEncoder(for: StatusRecord.Columns.poll.name).encode(poll)

            try StatusRecord.filter(StatusRecord.Columns.id == id)
                .updateAll($0, StatusRecord.Columns.poll.set(to: data))
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func delete(id: Status.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(updates: StatusRecord.filter(StatusRecord.Columns.id == id).deleteAll)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func unfollow(id: Account.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            let statusIds = try Status.Id.fetchAll(
                $0,
                StatusRecord.filter(StatusRecord.Columns.accountId == id).select(StatusRecord.Columns.id))

            try TimelineStatusJoin.filter(
                TimelineStatusJoin.Columns.timelineId == Timeline.home.id
                    && statusIds.contains(TimelineStatusJoin.Columns.statusId))
                .deleteAll($0)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func mute(id: Account.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            try StatusRecord.filter(StatusRecord.Columns.accountId == id).deleteAll($0)
            try NotificationRecord.filter(NotificationRecord.Columns.accountId == id).deleteAll($0)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func block(id: Account.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(updates: AccountRecord.filter(AccountRecord.Columns.id == id).deleteAll)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func insert(accounts: [Account]) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for account in accounts {
                try account.save($0)
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func insert(identityProofs: [IdentityProof], id: Account.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for identityProof in identityProofs {
                try IdentityProofRecord(
                    accountId: id,
                    provider: identityProof.provider,
                    providerUsername: identityProof.providerUsername,
                    profileUrl: identityProof.profileUrl,
                    proofUrl: identityProof.proofUrl,
                    updatedAt: identityProof.updatedAt)
                    .save($0)
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func insert(featuredTags: [FeaturedTag], id: Account.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for featuredTag in featuredTags {
                try FeaturedTagRecord(
                    id: featuredTag.id,
                    name: featuredTag.name,
                    url: featuredTag.url,
                    statusesCount: featuredTag.statusesCount,
                    lastStatusAt: featuredTag.lastStatusAt,
                    accountId: id)
                    .save($0)
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func insert(relationships: [Relationship]) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for relationship in relationships {
                try relationship.save($0)
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func setLists(_ lists: [List]) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for list in lists {
                try TimelineRecord(timeline: Timeline.list(list)).save($0)
            }

            try TimelineRecord
                .filter(!lists.map(\.id).contains(TimelineRecord.Columns.listId)
                            && TimelineRecord.Columns.listTitle != nil)
                .deleteAll($0)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func createList(_ list: List) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(updates: TimelineRecord(timeline: Timeline.list(list)).save)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func deleteList(id: List.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(updates: TimelineRecord.filter(TimelineRecord.Columns.listId == id).deleteAll)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func setFilters(_ filters: [Filter]) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for filter in filters {
                try filter.save($0)
            }

            try Filter.filter(!filters.map(\.id).contains(Filter.Columns.id)).deleteAll($0)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func createFilter(_ filter: Filter) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(updates: filter.save)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func deleteFilter(id: Filter.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(updates: Filter.filter(Filter.Columns.id == id).deleteAll)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func setLastReadId(_ id: String, markerTimeline: Marker.Timeline) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(updates: LastReadIdRecord(markerTimeline: markerTimeline, id: id).save)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func insert(notifications: [MastodonNotification]) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for notification in notifications {
                try notification.save($0)
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func insert(conversations: [Conversation]) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for conversation in conversations {
                try conversation.save($0)
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func update(emojis: [Emoji]) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for emoji in emojis {
                try emoji.save($0)
            }

            try Emoji.filter(!emojis.map(\.shortcode).contains(Emoji.Columns.shortcode)).deleteAll($0)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func updateUse(emoji: String, system: Bool) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            let count = try Int.fetchOne(
                $0,
                EmojiUse.filter(EmojiUse.Columns.system == system && EmojiUse.Columns.emoji == emoji)
                    .select(EmojiUse.Columns.count))

            try EmojiUse(emoji: emoji, system: system, lastUse: Date(), count: (count ?? 0) + 1).save($0)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func update(announcements: [Announcement]) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for announcement in announcements {
                try announcement.save($0)
            }

            try Announcement.filter(!announcements.map(\.id).contains(Announcement.Columns.id)).deleteAll($0)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func insert(results: Results) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for account in results.accounts {
                try account.save($0)
            }

            for status in results.statuses {
                try status.save($0)
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func timelinePublisher(_ timeline: Timeline) -> AnyPublisher<[CollectionSection], Error> {
        ValueObservation.tracking(
            TimelineItemsInfo.request(TimelineRecord.filter(TimelineRecord.Columns.id == timeline.id)).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .handleEvents(
                receiveSubscription: { _ in
                    if let ephemeralityId = timeline.ephemeralityId(id: id) {
                        Self.ephemeralTimelines.add(ephemeralityId)
                    }
                },
                receiveCancel: {
                    guard let ephemeralityId = timeline.ephemeralityId(id: id) else { return }

                    Self.ephemeralTimelines.remove(ephemeralityId)

                    if Self.ephemeralTimelines.count(for: ephemeralityId) == 0 {
                        databaseWriter.asyncWrite(TimelineRecord(timeline: timeline).delete) { _, _ in }
                    }
                })
            .combineLatest(activeFiltersPublisher)
            .compactMap { $0?.items(filters: $1) }
            .eraseToAnyPublisher()
    }

    func contextPublisher(id: Status.Id) -> AnyPublisher<[CollectionSection], Error> {
        ValueObservation.tracking(
            ContextItemsInfo.request(StatusRecord.filter(StatusRecord.Columns.id == id)).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .combineLatest(activeFiltersPublisher)
            .map { $0?.items(filters: $1) }
            .replaceNil(with: [])
            .eraseToAnyPublisher()
    }

    func listsPublisher() -> AnyPublisher<[Timeline], Error> {
        ValueObservation.tracking(TimelineRecord.filter(TimelineRecord.Columns.listId != nil)
                                    .order(TimelineRecord.Columns.listTitle.asc)
                                    .fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .tryMap { $0.map(Timeline.init(record:)).compactMap { $0 } }
            .eraseToAnyPublisher()
    }

    func expiredFiltersPublisher() -> AnyPublisher<[Filter], Error> {
        ValueObservation.tracking { try Filter.filter(Filter.Columns.expiresAt < Date()).fetchAll($0) }
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .eraseToAnyPublisher()
    }

    func profilePublisher(id: Account.Id) -> AnyPublisher<Profile, Error> {
        ValueObservation.tracking(ProfileInfo.request(AccountRecord.filter(AccountRecord.Columns.id == id)).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .compactMap { $0 }
            .map(Profile.init(info:))
            .eraseToAnyPublisher()
    }

    func relationshipPublisher(id: Account.Id) -> AnyPublisher<Relationship, Error> {
        ValueObservation.tracking(Relationship.filter(Relationship.Columns.id == id).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    // swiftlint:disable:next function_body_length
    func publisher(results: Results, limit: Int?) -> AnyPublisher<[CollectionSection], Error> {
        let accountIds = results.accounts.map(\.id)
        let statusIds = results.statuses.map(\.id)

        let accountsPublisher = ValueObservation.tracking(
            AccountInfo.request(
                AccountRecord.filter(accountIds.contains(AccountRecord.Columns.id)))
                .fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .map { infos -> [CollectionItem] in
                var accounts = infos.sorted {
                    accountIds.firstIndex(of: $0.record.id) ?? 0
                        < accountIds.firstIndex(of: $1.record.id) ?? 0
                }
                .map { CollectionItem.account(.init(info: $0), .withoutNote) }

                if let limit = limit, accounts.count >= limit {
                    accounts.append(.moreResults(.init(scope: .accounts)))
                }

                return accounts
            }

        let statusesPublisher = ValueObservation.tracking(
            StatusInfo.request(
                StatusRecord.filter(statusIds.contains(StatusRecord.Columns.id)))
                .fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .map { infos -> [CollectionItem] in
                var statuses = infos.sorted {
                    statusIds.firstIndex(of: $0.record.id) ?? 0
                        < statusIds.firstIndex(of: $1.record.id) ?? 0
                }
                .map {
                    CollectionItem.status(
                        .init(info: $0),
                        .init(showContentToggled: $0.showContentToggled,
                              showAttachmentsToggled: $0.showAttachmentsToggled))
                }

                if let limit = limit, statuses.count >= limit {
                    statuses.append(.moreResults(.init(scope: .statuses)))
                }

                return statuses
            }

        var hashtags = results.hashtags.map(CollectionItem.tag)

        if let limit = limit, hashtags.count >= limit {
            hashtags.append(.moreResults(.init(scope: .tags)))
        }

        return accountsPublisher.combineLatest(statusesPublisher)
            .map { accounts, statuses in
                [.init(items: accounts, titleLocalizedStringKey: "search.scope.accounts"),
                 .init(items: statuses, titleLocalizedStringKey: "search.scope.statuses"),
                 .init(items: hashtags, titleLocalizedStringKey: "search.scope.tags")]
                    .filter { !$0.items.isEmpty }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func notificationsPublisher(
        excludeTypes: Set<MastodonNotification.NotificationType>) -> AnyPublisher<[CollectionSection], Error> {
        ValueObservation.tracking(
            NotificationInfo.request(
                NotificationRecord.order(NotificationRecord.Columns.id.desc)
                    .filter(!excludeTypes.map(\.rawValue).contains(NotificationRecord.Columns.type))).fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .map { [.init(items: $0.map {
                let configuration: CollectionItem.StatusConfiguration?

                if $0.record.type == .mention, let statusInfo = $0.statusInfo {
                    configuration = CollectionItem.StatusConfiguration(
                        showContentToggled: statusInfo.showContentToggled,
                        showAttachmentsToggled: statusInfo.showAttachmentsToggled)
                } else {
                    configuration = nil
                }

                return .notification(MastodonNotification(info: $0), configuration)
            })] }
            .eraseToAnyPublisher()
    }

    func conversationsPublisher() -> AnyPublisher<[Conversation], Error> {
        ValueObservation.tracking(ConversationInfo.request(ConversationRecord.all()).fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .map {
                $0.sorted { $0.lastStatusInfo.record.createdAt > $1.lastStatusInfo.record.createdAt }
                    .map(Conversation.init(info:))
            }
            .eraseToAnyPublisher()
    }

    func pickerEmojisPublisher() -> AnyPublisher<[Emoji], Error> {
        ValueObservation.tracking(
            Emoji.filter(Emoji.Columns.visibleInPicker == true)
                .order(Emoji.Columns.shortcode.asc)
                .fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .eraseToAnyPublisher()
    }

    func emojiUses(limit: Int) -> AnyPublisher<[EmojiUse], Error> {
        databaseWriter.readPublisher(value: EmojiUse.all().order(EmojiUse.Columns.count.desc).limit(limit).fetchAll)
            .eraseToAnyPublisher()
    }

    func lastReadId(_ markerTimeline: Marker.Timeline) -> String? {
        try? databaseWriter.read {
            try String.fetchOne(
                $0,
                LastReadIdRecord.filter(LastReadIdRecord.Columns.markerTimeline == markerTimeline.rawValue)
                    .select(LastReadIdRecord.Columns.id))
        }
    }
}

private extension ContentDatabase {
    static let cleanAfterLastReadIdCount = 40

    static let ephemeralTimelines = NSCountedSet()

    static func fileURL(id: Identity.Id, appGroup: String) throws -> URL {
        try FileManager.default.databaseDirectoryURL(name: id.uuidString, appGroup: appGroup)
    }

    // swiftlint:disable:next function_body_length
    static func clean(_ databaseWriter: DatabaseWriter,
                      useHomeTimelineLastReadId: Bool,
                      useNotificationsLastReadId: Bool) throws {
        try databaseWriter.write {
            let notificationAccountIds: [Account.Id]
            let notificationStatusIds: [Status.Id]

            try ConversationRecord.deleteAll($0)
            try StatusAncestorJoin.deleteAll($0)
            try StatusDescendantJoin.deleteAll($0)

            if useNotificationsLastReadId {
                var notificationIds = try MastodonNotification.Id.fetchAll(
                    $0,
                    NotificationRecord.select(NotificationRecord.Columns.id)
                        .order(NotificationRecord.Columns.id.desc))

                if let lastReadId = try MastodonNotification.Id.fetchOne(
                    $0,
                    LastReadIdRecord.filter(
                        LastReadIdRecord.Columns.markerTimeline == Marker.Timeline.notifications.rawValue)
                        .select(LastReadIdRecord.Columns.id))
                    ?? notificationIds.first,
                   let index = notificationIds.firstIndex(of: lastReadId) {
                    notificationIds = Array(notificationIds.prefix(index + Self.cleanAfterLastReadIdCount))
                }

                try NotificationRecord.filter(!notificationIds.contains(NotificationRecord.Columns.id)).deleteAll($0)
                notificationAccountIds = try Account.Id.fetchAll(
                    $0,
                    NotificationRecord.select(NotificationRecord.Columns.accountId))
                notificationStatusIds = try Status.Id.fetchAll(
                    $0,
                    NotificationRecord.filter(
                        NotificationRecord.Columns.statusId != nil)
                        .select(NotificationRecord.Columns.statusId))
            } else {
                try NotificationRecord.deleteAll($0)
                notificationAccountIds = []
                notificationStatusIds = []
            }

            if useHomeTimelineLastReadId {
                try TimelineRecord.filter(TimelineRecord.Columns.id != Timeline.home.id).deleteAll($0)
                var statusIds = try Status.Id.fetchAll(
                    $0,
                    TimelineStatusJoin.select(TimelineStatusJoin.Columns.statusId)
                        .order(TimelineStatusJoin.Columns.statusId.desc))

                if let lastReadId = try Status.Id.fetchOne(
                    $0,
                    LastReadIdRecord.filter(LastReadIdRecord.Columns.markerTimeline == Marker.Timeline.home.rawValue)
                        .select(LastReadIdRecord.Columns.id))
                    ?? statusIds.first,
                   let index = statusIds.firstIndex(of: lastReadId) {
                    statusIds = Array(statusIds.prefix(index + Self.cleanAfterLastReadIdCount))
                }

                statusIds += notificationStatusIds
                statusIds += try Status.Id.fetchAll(
                    $0,
                    StatusRecord.filter(statusIds.contains(StatusRecord.Columns.id)
                                            && StatusRecord.Columns.reblogId != nil)
                        .select(StatusRecord.Columns.reblogId))
                try StatusRecord.filter(!statusIds.contains(StatusRecord.Columns.id)).deleteAll($0)
                var accountIds = try Account.Id.fetchAll($0, StatusRecord.select(StatusRecord.Columns.accountId))
                accountIds += notificationAccountIds
                accountIds += try Account.Id.fetchAll(
                    $0,
                    AccountRecord.filter(accountIds.contains(AccountRecord.Columns.id)
                                            && AccountRecord.Columns.movedId != nil)
                        .select(AccountRecord.Columns.movedId))
                try AccountRecord.filter(!accountIds.contains(AccountRecord.Columns.id)).deleteAll($0)
            } else {
                try TimelineRecord.deleteAll($0)
                try StatusRecord.filter(!notificationStatusIds.contains(StatusRecord.Columns.id)).deleteAll($0)
                try AccountRecord.filter(!notificationAccountIds.contains(AccountRecord.Columns.id)).deleteAll($0)
            }
        }
    }
}
// swiftlint:enable file_length
