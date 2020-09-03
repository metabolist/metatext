// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import GRDB
import Mastodon

// swiftlint:disable file_length
struct ContentDatabase {
    private let databaseQueue: DatabaseQueue

    init(identityID: UUID, environment: AppEnvironment) throws {
        if environment.inMemoryContent {
            databaseQueue = DatabaseQueue()
        } else {
            databaseQueue = try DatabaseQueue(path: try Self.fileURL(identityID: identityID).path)
        }

        try Self.migrate(databaseQueue)
    }
}

extension ContentDatabase {
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
        try FileManager.default.databaseDirectoryURL().appendingPathComponent(identityID.uuidString + ".sqlite")
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

extension Account: FetchableRecord, PersistableRecord {
    public static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        APIDecoder()
    }

    public static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        APIEncoder()
    }
}

private struct TimelineStatusJoin: Codable, FetchableRecord, PersistableRecord {
    let timelineId: String
    let statusId: String

    static let status = belongsTo(StoredStatus.self)
}

extension Timeline: FetchableRecord, PersistableRecord {
    enum Columns: String, ColumnExpression {
        case id, listTitle
    }

    public init(row: Row) {
        switch (row[Columns.id] as String, row[Columns.listTitle] as String?) {
        case (Timeline.home.id, _):
            self = .home
        case (Timeline.local.id, _):
            self = .local
        case (Timeline.federated.id, _):
            self = .federated
        case (let id, .some(let title)):
            self = .list(MastodonList(id: id, title: title))
        default:
            self = .tag(row[Columns.id])
        }
    }

    public func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id

        if case let .list(list) = self {
            container[Columns.listTitle] = list.title
        }
    }
}

private extension Timeline {
    static let statusJoins = hasMany(TimelineStatusJoin.self)
    static let statuses = hasMany(
        StoredStatus.self,
        through: statusJoins,
        using: TimelineStatusJoin.status)
        .order(Column("createdAt").desc)

    var statuses: QueryInterfaceRequest<StatusResult> {
        request(for: Self.statuses).statusResultRequest
    }
}

private struct StatusContextJoin: Codable, FetchableRecord, PersistableRecord {
    enum Section: String, Codable {
        case ancestors
        case descendants
    }

    let parentId: String
    let statusId: String
    let section: Section
    let index: Int

    static let status = belongsTo(StoredStatus.self, using: ForeignKey([Column("statusId")]))
}

private extension StoredStatus {
    static let ancestorJoins = hasMany(StatusContextJoin.self, using: ForeignKey([Column("parentID")]))
        .filter(Column("section") == StatusContextJoin.Section.ancestors.rawValue)
        .order(Column("index"))
    static let descendantJoins = hasMany(StatusContextJoin.self, using: ForeignKey([Column("parentID")]))
        .filter(Column("section") == StatusContextJoin.Section.descendants.rawValue)
        .order(Column("index"))
    static let ancestors = hasMany(StoredStatus.self,
                                   through: ancestorJoins,
                                   using: StatusContextJoin.status)
    static let descendants = hasMany(StoredStatus.self,
                                   through: descendantJoins,
                                   using: StatusContextJoin.status)

    var ancestors: QueryInterfaceRequest<StatusResult> {
        request(for: Self.ancestors).statusResultRequest
    }

    var descendants: QueryInterfaceRequest<StatusResult> {
        request(for: Self.descendants).statusResultRequest
    }
}

private extension QueryInterfaceRequest where RowDecoder == StoredStatus {
    var statusResultRequest: QueryInterfaceRequest<StatusResult> {
        including(required: StoredStatus.account)
        .including(optional: StoredStatus.reblogAccount)
        .including(optional: StoredStatus.reblog)
        .asRequest(of: StatusResult.self)
    }
}

extension Filter: FetchableRecord, PersistableRecord {
    public static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        APIDecoder()
    }

    public static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        APIEncoder()
    }
}

struct StoredStatus: Codable, Hashable {
    let id: String
    let uri: String
    let createdAt: Date
    let accountId: String
    let content: HTML
    let visibility: Status.Visibility
    let sensitive: Bool
    let spoilerText: String
    let mediaAttachments: [Attachment]
    let mentions: [Mention]
    let tags: [Tag]
    let emojis: [Emoji]
    let reblogsCount: Int
    let favouritesCount: Int
    let repliesCount: Int
    let application: Application?
    let url: URL?
    let inReplyToId: String?
    let inReplyToAccountId: String?
    let reblogId: String?
    let poll: Poll?
    let card: Card?
    let language: String?
    let text: String?
    let favourited: Bool
    let reblogged: Bool
    let muted: Bool
    let bookmarked: Bool
    let pinned: Bool?
}

private extension StoredStatus {
    static let account = belongsTo(Account.self, key: "account")
    static let reblogAccount = hasOne(Account.self, through: Self.reblog, using: Self.account, key: "reblogAccount")
    static let reblog = belongsTo(StoredStatus.self, key: "reblog")

    var account: QueryInterfaceRequest<Account> {
        request(for: Self.account)
    }

    var reblogAccount: QueryInterfaceRequest<Account> {
        request(for: Self.reblogAccount)
    }

    var reblog: QueryInterfaceRequest<StoredStatus> {
        request(for: Self.reblog)
    }

    init(status: Status) {
        id = status.id
        uri = status.uri
        createdAt = status.createdAt
        accountId = status.account.id
        content = status.content
        visibility = status.visibility
        sensitive = status.sensitive
        spoilerText = status.spoilerText
        mediaAttachments = status.mediaAttachments
        mentions = status.mentions
        tags = status.tags
        emojis = status.emojis
        reblogsCount = status.reblogsCount
        favouritesCount = status.favouritesCount
        repliesCount = status.repliesCount
        application = status.application
        url = status.url
        inReplyToId = status.inReplyToId
        inReplyToAccountId = status.inReplyToAccountId
        reblogId = status.reblog?.id
        poll = status.poll
        card = status.card
        language = status.language
        text = status.text
        favourited = status.favourited
        reblogged = status.reblogged
        muted = status.muted
        bookmarked = status.bookmarked
        pinned = status.pinned
    }
}

extension StoredStatus: FetchableRecord, PersistableRecord {
    static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        APIDecoder()
    }

    static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        APIEncoder()
    }
}

struct StatusResult: Codable, Hashable, FetchableRecord {
    let account: Account
    let status: StoredStatus
    let reblogAccount: Account?
    let reblog: StoredStatus?
}

private extension Status {
    func save(_ db: Database) throws {
        try account.save(db)

        if let reblog = reblog {
            try reblog.account.save(db)
            try StoredStatus(status: reblog).save(db)
        }

        try StoredStatus(status: self).save(db)
    }

    convenience init(statusResult: StatusResult) {
        var reblog: Status?

        if let reblogResult = statusResult.reblog, let reblogAccount = statusResult.reblogAccount {
            reblog = Status(storedStatus: reblogResult, account: reblogAccount, reblog: nil)
        }

        self.init(storedStatus: statusResult.status, account: statusResult.account, reblog: reblog)
    }

    convenience init(storedStatus: StoredStatus, account: Account, reblog: Status?) {
        self.init(
            id: storedStatus.id,
            uri: storedStatus.uri,
            createdAt: storedStatus.createdAt,
            account: account,
            content: storedStatus.content,
            visibility: storedStatus.visibility,
            sensitive: storedStatus.sensitive,
            spoilerText: storedStatus.spoilerText,
            mediaAttachments: storedStatus.mediaAttachments,
            mentions: storedStatus.mentions,
            tags: storedStatus.tags,
            emojis: storedStatus.emojis,
            reblogsCount: storedStatus.reblogsCount,
            favouritesCount: storedStatus.favouritesCount,
            repliesCount: storedStatus.repliesCount,
            application: storedStatus.application,
            url: storedStatus.url,
            inReplyToId: storedStatus.inReplyToId,
            inReplyToAccountId: storedStatus.inReplyToAccountId,
            reblog: reblog,
            poll: storedStatus.poll,
            card: storedStatus.card,
            language: storedStatus.language,
            text: storedStatus.text,
            favourited: storedStatus.favourited,
            reblogged: storedStatus.reblogged,
            muted: storedStatus.muted,
            bookmarked: storedStatus.bookmarked,
            pinned: storedStatus.pinned)
    }
}
// swiftlint:enable file_length
