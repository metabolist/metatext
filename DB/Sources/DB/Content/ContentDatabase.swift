// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import GRDB
import Keychain
import Mastodon
import Secrets

public struct ContentDatabase {
    private let databaseWriter: DatabaseWriter

    public init(identityID: UUID, inMemory: Bool, keychain: Keychain.Type) throws {
        if inMemory {
            databaseWriter = DatabaseQueue()
        } else {
            let path = try Self.fileURL(identityID: identityID).path
            var configuration = Configuration()

            configuration.prepareDatabase {
                try $0.usePassphrase(Secrets.databaseKey(identityID: identityID, keychain: keychain))
            }

            databaseWriter = try DatabasePool(path: path, configuration: configuration)
        }

        try migrator.migrate(databaseWriter)
        try clean()
    }
}

public extension ContentDatabase {
    static func delete(forIdentityID identityID: UUID) throws {
        try FileManager.default.removeItem(at: fileURL(identityID: identityID))
    }

    func insert(status: Status) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(updates: status.save)
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func insert(statuses: [Status], timeline: Timeline) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            try timeline.save($0)

            for status in statuses {
                try status.save($0)

                try TimelineStatusJoin(timelineId: timeline.id, statusId: status.id).save($0)
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func insert(context: Context, parentID: String) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for status in context.ancestors + context.descendants {
                try status.save($0)
            }

            for (section, statuses) in [(StatusContextJoin.Section.ancestors, context.ancestors),
                                        (StatusContextJoin.Section.descendants, context.descendants)] {
                for (index, status) in statuses.enumerated() {
                    try StatusContextJoin(
                        parentId: parentID,
                        statusId: status.id,
                        section: section,
                        index: index)
                        .save($0)
                }

               try StatusContextJoin.filter(
                StatusContextJoin.Columns.parentId == parentID
                    && StatusContextJoin.Columns.section == section.rawValue
                    && !statuses.map(\.id).contains(StatusContextJoin.Columns.statusId))
                    .deleteAll($0)
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func insert(pinnedStatuses: [Status], accountID: String) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for (index, status) in pinnedStatuses.enumerated() {
                try status.save($0)

                try AccountPinnedStatusJoin(accountId: accountID, statusId: status.id, index: index).save($0)
            }

            try AccountPinnedStatusJoin.filter(
                AccountPinnedStatusJoin.Columns.accountId == accountID
                    && !pinnedStatuses.map(\.id).contains(AccountPinnedStatusJoin.Columns.statusId))
                .deleteAll($0)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func insert(
        statuses: [Status],
        accountID: String,
        collection: ProfileCollection) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for status in statuses {
                try status.save($0)

                try AccountStatusJoin(accountId: accountID, statusId: status.id, collection: collection).save($0)
            }
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
                try Timeline.list(list).save($0)
            }

            try Timeline
                .filter(!(Timeline.authenticatedDefaults.map(\.id) + lists.map(\.id)).contains(Timeline.Columns.id)
                            && Timeline.Columns.listTitle != nil)
                .deleteAll($0)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func createList(_ list: List) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(updates: Timeline.list(list).save)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func deleteList(id: String) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(updates: Timeline.filter(Timeline.Columns.id == id).deleteAll)
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

    func deleteFilter(id: String) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(updates: Filter.filter(Filter.Columns.id == id).deleteAll)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func statusesObservation(timeline: Timeline) -> AnyPublisher<[[Status]], Error> {
        ValueObservation.tracking(timeline.statuses.fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .map { [$0.map(Status.init(result:))] }
            .eraseToAnyPublisher()
    }

    func contextObservation(parentID: String) -> AnyPublisher<[[Status]], Error> {
        ValueObservation.tracking { db -> [[StatusResult]] in
            guard let parent = try StatusResult.request(StatusRecord.filter(StatusRecord.Columns.id == parentID))
                    .fetchOne(db) else {
                return [[]]
            }

            let ancestors = try parent.status.ancestors.fetchAll(db)
            let descendants = try parent.status.descendants.fetchAll(db)

            return [ancestors, [parent], descendants]
        }
        .removeDuplicates()
        .publisher(in: databaseWriter)
        .map { $0.map { $0.map(Status.init(result:)) } }
        .eraseToAnyPublisher()
    }

    func statusesObservation(
        accountID: String,
        collection: ProfileCollection) -> AnyPublisher<[[Status]], Error> {
        ValueObservation.tracking { db -> [[StatusResult]] in
            let statuses = try StatusResult.request(StatusRecord.filter(
                AccountStatusJoin
                    .select(AccountStatusJoin.Columns.statusId, as: String.self)
                    .filter(sql: "accountId = ? AND collection = ?", arguments: [accountID, collection.rawValue])
                    .contains(StatusRecord.Columns.id))
                .order(StatusRecord.Columns.createdAt.desc))
                .fetchAll(db)

            if
                case .statuses = collection,
                let accountRecord = try AccountRecord.filter(AccountRecord.Columns.id == accountID).fetchOne(db) {
                let pinnedStatuses = try accountRecord.pinnedStatuses.fetchAll(db)

                return [pinnedStatuses, statuses]
            } else {
                return [statuses]
            }
        }
        .removeDuplicates()
        .publisher(in: databaseWriter)
        .map { $0.map { $0.map(Status.init(result:)) } }
        .eraseToAnyPublisher()
    }

    func listsObservation() -> AnyPublisher<[Timeline], Error> {
        ValueObservation.tracking(Timeline.filter(Timeline.Columns.listTitle != nil)
                                    .order(Timeline.Columns.listTitle.asc)
                                    .fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .eraseToAnyPublisher()
    }

    func activeFiltersObservation(date: Date, context: Filter.Context? = nil) -> AnyPublisher<[Filter], Error> {
        ValueObservation.tracking(
            Filter.filter(Filter.Columns.expiresAt == nil || Filter.Columns.expiresAt > date).fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .map {
                guard let context = context else { return $0 }

                return $0.filter { $0.context.contains(context) }
            }
            .eraseToAnyPublisher()
    }

    func expiredFiltersObservation(date: Date) -> AnyPublisher<[Filter], Error> {
        ValueObservation.tracking(Filter.filter(Filter.Columns.expiresAt < date).fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .eraseToAnyPublisher()
    }

    func accountObservation(id: String) -> AnyPublisher<Account?, Error> {
        ValueObservation.tracking(AccountResult.request(AccountRecord.filter(AccountRecord.Columns.id == id)).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .map {
                if let result = $0 {
                    return Account(result: result)
                } else {
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    func accountListObservation(_ list: AccountList) -> AnyPublisher<[Account], Error> {
        ValueObservation.tracking(list.accounts.fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .map { $0.map(Account.init(result:)) }
            .eraseToAnyPublisher()
    }
}

private extension ContentDatabase {
    static func fileURL(identityID: UUID) throws -> URL {
        try FileManager.default.databaseDirectoryURL(name: identityID.uuidString)
    }

    func clean() throws {
        try databaseWriter.write {
            try Timeline.deleteAll($0)
            try StatusRecord.deleteAll($0)
            try AccountRecord.deleteAll($0)
            try AccountList.deleteAll($0)
        }
    }
}
