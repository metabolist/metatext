// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import GRDB
import Keychain
import Mastodon
import Secrets

// swiftlint:disable file_length
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
        clean()
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
                    Column("parentId") == parentID
                        && Column("section") == section.rawValue
                        && !statuses.map(\.id).contains(Column("statusId")))
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
                Column("accountId") == accountID
                    && !pinnedStatuses.map(\.id).contains(Column("statusId")))
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

    func insert(accounts: [Account]) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for account in accounts {
                try account.save($0)
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
                .filter(!(Timeline.authenticatedDefaults.map(\.id) + lists.map(\.id)).contains(Column("id"))
                            && Column("listTitle") != nil)
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
        databaseWriter.writePublisher(updates: Timeline.filter(Column("id") == id).deleteAll)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func setFilters(_ filters: [Filter]) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            for filter in filters {
                try filter.save($0)
            }

            try Filter.filter(!filters.map(\.id).contains(Column("id"))).deleteAll($0)
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
        databaseWriter.writePublisher(updates: Filter.filter(Column("id") == id).deleteAll)
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
            guard let parent = try StatusRecord.filter(Column("id") == parentID).statusResultRequest.fetchOne(db) else {
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
            let statuses = try StatusRecord.filter(
                AccountStatusJoin
                    .select(Column("statusId"), as: String.self)
                    .filter(sql: "accountId = ? AND collection = ?", arguments: [accountID, collection.rawValue])
                    .contains(Column("id")))
                .order(Column("createdAt").desc)
                .statusResultRequest
                .fetchAll(db)

            if
                case .statuses = collection,
                let accountRecord = try AccountRecord.filter(Column("id") == accountID).fetchOne(db) {
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
        ValueObservation.tracking(Timeline.filter(Column("listTitle") != nil)
                                    .order(Column("listTitle").asc)
                                    .fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .eraseToAnyPublisher()
    }

    func activeFiltersObservation(date: Date, context: Filter.Context? = nil) -> AnyPublisher<[Filter], Error> {
        ValueObservation.tracking(Filter.filter(Column("expiresAt") == nil || Column("expiresAt") > date).fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .map {
                guard let context = context else { return $0 }

                return $0.filter { $0.context.contains(context) }
            }
            .eraseToAnyPublisher()
    }

    func expiredFiltersObservation(date: Date) -> AnyPublisher<[Filter], Error> {
        ValueObservation.tracking(Filter.filter(Column("expiresAt") < date).fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .eraseToAnyPublisher()
    }

    func accountObservation(id: String) -> AnyPublisher<Account?, Error> {
        ValueObservation.tracking(AccountRecord.filter(Column("id") == id).accountResultRequest.fetchOne)
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
}

private extension ContentDatabase {
    static func fileURL(identityID: UUID) throws -> URL {
        try FileManager.default.databaseDirectoryURL(name: identityID.uuidString)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("0.1.0") { db in
            try db.create(table: "accountRecord") { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("username", .text).notNull()
                t.column("acct", .text).notNull()
                t.column("displayName", .text).notNull()
                t.column("locked", .boolean).notNull()
                t.column("createdAt", .date).notNull()
                t.column("followersCount", .integer).notNull()
                t.column("followingCount", .integer).notNull()
                t.column("statusesCount", .integer).notNull()
                t.column("note", .text).notNull()
                t.column("url", .text).notNull()
                t.column("avatar", .text).notNull()
                t.column("avatarStatic", .text).notNull()
                t.column("header", .text).notNull()
                t.column("headerStatic", .text).notNull()
                t.column("fields", .blob).notNull()
                t.column("emojis", .blob).notNull()
                t.column("bot", .boolean).notNull()
                t.column("discoverable", .boolean)
                t.column("movedId", .text).references("accountRecord", column: "id")
            }

            try db.create(table: "statusRecord") { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("uri", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("accountId", .text).notNull().references("accountRecord", column: "id")
                t.column("content", .text).notNull()
                t.column("visibility", .text).notNull()
                t.column("sensitive", .boolean).notNull()
                t.column("spoilerText", .text).notNull()
                t.column("mediaAttachments", .blob).notNull()
                t.column("mentions", .blob).notNull()
                t.column("tags", .blob).notNull()
                t.column("emojis", .blob).notNull()
                t.column("reblogsCount", .integer).notNull()
                t.column("favouritesCount", .integer).notNull()
                t.column("repliesCount", .integer).notNull()
                t.column("application", .blob)
                t.column("url", .text)
                t.column("inReplyToId", .text)
                t.column("inReplyToAccountId", .text)
                t.column("reblogId", .text).references("statusRecord", column: "id")
                t.column("poll", .blob)
                t.column("card", .blob)
                t.column("language", .text)
                t.column("text", .text)
                t.column("favourited", .boolean).notNull()
                t.column("reblogged", .boolean).notNull()
                t.column("muted", .boolean).notNull()
                t.column("bookmarked", .boolean).notNull()
                t.column("pinned", .boolean)
            }

            try db.create(table: "timeline") { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("listTitle", .text).indexed().collate(.localizedCaseInsensitiveCompare)
            }

            try db.create(table: "timelineStatusJoin") { t in
                t.column("timelineId", .text).indexed().notNull()
                    .references("timeline", column: "id", onDelete: .cascade, onUpdate: .cascade)
                t.column("statusId", .text).indexed().notNull()
                    .references("statusRecord", column: "id", onDelete: .cascade, onUpdate: .cascade)

                t.primaryKey(["timelineId", "statusId"], onConflict: .replace)
            }

            try db.create(table: "filter") { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("phrase", .text).notNull()
                t.column("context", .blob).notNull()
                t.column("expiresAt", .date).indexed()
                t.column("irreversible", .boolean).notNull()
                t.column("wholeWord", .boolean).notNull()
            }

            try db.create(table: "statusContextJoin") { t in
                t.column("parentId", .text).indexed().notNull()
                    .references("statusRecord", column: "id", onDelete: .cascade, onUpdate: .cascade)
                t.column("statusId", .text).indexed().notNull()
                    .references("statusRecord", column: "id", onDelete: .cascade, onUpdate: .cascade)
                t.column("section", .text).indexed().notNull()
                t.column("index", .integer).notNull()

                t.primaryKey(["parentId", "statusId"], onConflict: .replace)
            }

            try db.create(table: "accountPinnedStatusJoin") { t in
                t.column("accountId", .text).indexed().notNull()
                    .references("accountRecord", column: "id", onDelete: .cascade, onUpdate: .cascade)
                t.column("statusId", .text).indexed().notNull()
                    .references("statusRecord", column: "id", onDelete: .cascade, onUpdate: .cascade)
                t.column("index", .integer).notNull()

                t.primaryKey(["accountId", "statusId"], onConflict: .replace)
            }

            try db.create(table: "accountStatusJoin") { t in
                t.column("accountId", .text).indexed().notNull()
                    .references("accountRecord", column: "id", onDelete: .cascade, onUpdate: .cascade)
                t.column("statusId", .text).indexed().notNull()
                    .references("statusRecord", column: "id", onDelete: .cascade, onUpdate: .cascade)
                t.column("collection", .text).indexed().notNull()

                t.primaryKey(["accountId", "statusId", "collection"], onConflict: .replace)
            }
        }

        return migrator
    }

    func clean() {
        databaseWriter.asyncWrite {
            try TimelineStatusJoin.filter(Column("id") != Timeline.home.id).deleteAll($0)
        } completion: { _, _ in }
        databaseWriter.asyncWrite { try StatusContextJoin.deleteAll($0) } completion: { _, _ in }
        databaseWriter.asyncWrite { try AccountPinnedStatusJoin.deleteAll($0) } completion: { _, _ in }
        databaseWriter.asyncWrite { try AccountStatusJoin.deleteAll($0) } completion: { _, _ in }
    }
}
// swiftlint:enable file_length
