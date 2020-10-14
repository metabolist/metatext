// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import GRDB
import Keychain
import Mastodon
import Secrets

public struct ContentDatabase {
    public let activeFiltersPublisher: AnyPublisher<[Filter], Error>

    private let databaseWriter: DatabaseWriter

    public init(id: Identity.Id, inMemory: Bool, keychain: Keychain.Type) throws {
        if inMemory {
            databaseWriter = DatabaseQueue()
        } else {
            let path = try Self.fileURL(id: id).path
            var configuration = Configuration()

            configuration.prepareDatabase {
                try $0.usePassphrase(Secrets.databaseKey(identityId: id, keychain: keychain))
            }

            databaseWriter = try DatabasePool(path: path, configuration: configuration)
        }

        try Self.migrator.migrate(databaseWriter)
        try Self.clean(databaseWriter)

        activeFiltersPublisher = ValueObservation.tracking {
            try Filter.filter(Filter.Columns.expiresAt == nil || Filter.Columns.expiresAt > Date()).fetchAll($0)
        }
        .removeDuplicates()
        .publisher(in: databaseWriter)
        .eraseToAnyPublisher()
    }
}

public extension ContentDatabase {
    static func delete(id: Identity.Id) throws {
        try FileManager.default.removeItem(at: fileURL(id: id))
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

    func append(accounts: [Account], toList list: AccountList) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            try list.save($0)

            let count = try list.accounts.fetchCount($0)

            for (index, account) in accounts.enumerated() {
                try account.save($0)
                try AccountListJoin(accountId: account.id, listId: list.id, index: count + index).save($0)
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

    func timelinePublisher(_ timeline: Timeline) -> AnyPublisher<[[CollectionItem]], Error> {
        ValueObservation.tracking(
            TimelineItemsInfo.request(TimelineRecord.filter(TimelineRecord.Columns.id == timeline.id)).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .combineLatest(activeFiltersPublisher)
            .compactMap { $0?.items(filters: $1) }
            .eraseToAnyPublisher()
    }

    func contextPublisher(id: Status.Id) -> AnyPublisher<[[CollectionItem]], Error> {
        ValueObservation.tracking(
            ContextItemsInfo.request(StatusRecord.filter(StatusRecord.Columns.id == id)).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .combineLatest(activeFiltersPublisher)
            .compactMap { $0?.items(filters: $1) }
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

    func accountPublisher(id: Account.Id) -> AnyPublisher<Account, Error> {
        ValueObservation.tracking(AccountInfo.request(AccountRecord.filter(AccountRecord.Columns.id == id)).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .compactMap { $0 }
            .map(Account.init(info:))
            .eraseToAnyPublisher()
    }

    func accountListPublisher(_ list: AccountList) -> AnyPublisher<[Account], Error> {
        ValueObservation.tracking(list.accounts.fetchAll)
            .removeDuplicates()
            .map { $0.map(Account.init(info:)) }
            .publisher(in: databaseWriter)
            .eraseToAnyPublisher()
    }
}

private extension ContentDatabase {
    static func fileURL(id: Identity.Id) throws -> URL {
        try FileManager.default.databaseDirectoryURL(name: id.uuidString)
    }

    static func clean(_ databaseWriter: DatabaseWriter) throws {
        try databaseWriter.write {
            try TimelineRecord.deleteAll($0)
            try StatusRecord.deleteAll($0)
            try AccountRecord.deleteAll($0)
            try AccountList.deleteAll($0)
        }
    }
}
