// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import GRDB
import Keychain
import Mastodon
import Secrets

public struct ContentDatabase {
    private let databaseQueue: DatabaseQueue

    public init(identityID: UUID, inMemory: Bool, keychain: Keychain.Type) throws {
        if inMemory {
            databaseQueue = DatabaseQueue()
        } else {
            let path = try Self.fileURL(identityID: identityID).path
            var configuration = Configuration()

            configuration.prepareDatabase = { db in
                let passphrase = try Secrets.databasePassphrase(identityID: identityID, keychain: keychain)
                try db.usePassphrase(passphrase)
            }

            databaseQueue = try DatabaseQueue(path: path, configuration: configuration)
        }

        try Self.migrate(databaseQueue)
    }
}

public extension ContentDatabase {
    static func delete(forIdentityID identityID: UUID) throws {
        try FileManager.default.removeItem(at: try fileURL(identityID: identityID))
    }

    func insert(status: Status) -> AnyPublisher<Never, Error> {
        databaseQueue.writePublisher(updates: status.save)
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func insert(statuses: [Status], timeline: Timeline) -> AnyPublisher<Never, Error> {
        databaseQueue.writePublisher {
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
        databaseQueue.writePublisher {
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
                        && Column("index") >= statuses.count)
                    .deleteAll($0)
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func setLists(_ lists: [MastodonList]) -> AnyPublisher<Never, Error> {
        databaseQueue.writePublisher {
            for list in lists {
                try Timeline.list(list).save($0)
            }

            try Timeline.filter(!(Timeline.nonLists.map(\.id) + lists.map(\.id)).contains(Column("id"))).deleteAll($0)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func createList(_ list: MastodonList) -> AnyPublisher<Never, Error> {
        databaseQueue.writePublisher(updates: Timeline.list(list).save)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func deleteList(id: String) -> AnyPublisher<Never, Error> {
        databaseQueue.writePublisher(updates: Timeline.filter(Column("id") == id).deleteAll)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func setFilters(_ filters: [Filter]) -> AnyPublisher<Never, Error> {
        databaseQueue.writePublisher {
            for filter in filters {
                try filter.save($0)
            }

            try Filter.filter(!filters.map(\.id).contains(Column("id"))).deleteAll($0)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func createFilter(_ filter: Filter) -> AnyPublisher<Never, Error> {
        databaseQueue.writePublisher(updates: filter.save)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func deleteFilter(id: String) -> AnyPublisher<Never, Error> {
        databaseQueue.writePublisher(updates: Filter.filter(Column("id") == id).deleteAll)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func statusesObservation(timeline: Timeline) -> AnyPublisher<[[Status]], Error> {
        ValueObservation.tracking(timeline.statuses.fetchAll)
            .removeDuplicates()
            .publisher(in: databaseQueue)
            .map { [$0.map(Status.init(statusResult:))] }
            .eraseToAnyPublisher()
    }

    func contextObservation(parentID: String) -> AnyPublisher<[[Status]], Error> {
        ValueObservation.tracking { db -> [[StatusResult]] in
            guard let parent = try StoredStatus.filter(Column("id") == parentID).statusResultRequest.fetchOne(db) else {
                return [[]]
            }

            let ancestors = try parent.status.ancestors.fetchAll(db)
            let descendants = try parent.status.descendants.fetchAll(db)

            return [ancestors, [parent], descendants]
        }
        .removeDuplicates()
        .publisher(in: databaseQueue)
        .map { $0.map { $0.map(Status.init(statusResult:)) } }
        .eraseToAnyPublisher()
    }

    func listsObservation() -> AnyPublisher<[Timeline], Error> {
        ValueObservation.tracking(Timeline.filter(!Timeline.nonLists.map(\.id).contains(Column("id")))
                                    .order(Column("listTitle").collating(.localizedCaseInsensitiveCompare).asc)
                                    .fetchAll)
            .removeDuplicates()
            .publisher(in: databaseQueue)
            .eraseToAnyPublisher()
    }

    func activeFiltersObservation(date: Date, context: Filter.Context? = nil) -> AnyPublisher<[Filter], Error> {
        ValueObservation.tracking(Filter.filter(Column("expiresAt") == nil || Column("expiresAt") > date).fetchAll)
            .removeDuplicates()
            .publisher(in: databaseQueue)
            .map {
                guard let context = context else { return $0 }

                return $0.filter { $0.context.contains(context) }
            }
            .eraseToAnyPublisher()
    }

    func expiredFiltersObservation(date: Date) -> AnyPublisher<[Filter], Error> {
        ValueObservation.tracking(Filter.filter(Column("expiresAt") < date).fetchAll)
            .removeDuplicates()
            .publisher(in: databaseQueue)
            .eraseToAnyPublisher()
    }
}

private extension ContentDatabase {
    static func fileURL(identityID: UUID) throws -> URL {
        try FileManager.default.databaseDirectoryURL(name: identityID.uuidString)
    }

    // swiftlint:disable function_body_length
    static func migrate(_ writer: DatabaseWriter) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createStatuses") { db in
            try db.create(table: "account", ifNotExists: true) { t in
                t.column("id", .text).notNull().primaryKey(onConflict: .replace)
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
                t.column("moved", .boolean)
                t.column("discoverable", .boolean)
            }

            try db.create(table: "storedStatus", ifNotExists: true) { t in
                t.column("id", .text).notNull().primaryKey(onConflict: .replace)
                t.column("uri", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("accountId", .text).indexed().notNull().references("account", column: "id")
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
                t.column("reblogId", .text).indexed().references("storedStatus", column: "id")
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

            try db.create(table: "timeline", ifNotExists: true) { t in
                t.column("id", .text).notNull().primaryKey(onConflict: .replace)
                t.column("listTitle", .text)
            }

            try db.create(table: "timelineStatusJoin", ifNotExists: true) { t in
                t.column("timelineId", .text)
                    .indexed()
                    .notNull()
                    .references("timeline", column: "id", onDelete: .cascade, onUpdate: .cascade)
                t.column("statusId", .text)
                    .indexed()
                    .notNull()
                    .references("storedStatus", column: "id", onDelete: .cascade, onUpdate: .cascade)

                t.primaryKey(["timelineId", "statusId"], onConflict: .replace)
            }

            try db.create(table: "statusContextJoin", ifNotExists: true) { t in
                t.column("parentId", .text)
                    .indexed()
                    .notNull()
                    .references("storedStatus", column: "id", onDelete: .cascade, onUpdate: .cascade)
                t.column("statusId", .text)
                    .indexed()
                    .notNull()
                    .references("storedStatus", column: "id", onDelete: .cascade, onUpdate: .cascade)
                t.column("section", .text).notNull()
                t.column("index", .integer).notNull()

                t.primaryKey(["parentId", "statusId"], onConflict: .replace)
            }

            try db.create(table: "filter", ifNotExists: true) { t in
                t.column("id", .text).notNull().primaryKey(onConflict: .replace)
                t.column("phrase", .text).notNull()
                t.column("context", .blob).notNull()
                t.column("expiresAt", .date)
                t.column("irreversible", .boolean).notNull()
                t.column("wholeWord", .boolean).notNull()
            }
        }

        try migrator.migrate(writer)
    }
    // swiftlint:enable function_body_length
}
