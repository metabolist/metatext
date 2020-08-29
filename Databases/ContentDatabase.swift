// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import GRDB

// swiftlint:disable file_length
struct ContentDatabase {
    private let databaseQueue: DatabaseQueue

    init(identityID: UUID, environment: AppEnvironment) throws {
        guard
            let documentsDirectory = NSSearchPathForDirectoriesInDomains(
                .documentDirectory,
                .userDomainMask, true)
                .first
        else { throw DatabaseError.documentsDirectoryNotFound }

        if environment.inMemoryContent {
            databaseQueue = DatabaseQueue()
        } else {
            databaseQueue = try DatabaseQueue(path: "\(documentsDirectory)/\(identityID.uuidString).sqlite3")
        }

        try Self.migrate(databaseQueue)
        try Self.createTemporaryTables(databaseQueue)
        Self.attributedStringCache = environment.attributedStringCache
    }
}

extension ContentDatabase {
    func insert(statuses: [Status], collection: StatusCollection? = nil) -> AnyPublisher<Never, Error> {
        databaseQueue.writePublisher {
            try collection?.save($0)

            for status in statuses {
                for component in status.storedComponents() {
                    try component.save($0)
                }

                try collection?.joinRecord(status: status).save($0)
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

    func statusesObservation(timeline: Timeline) -> AnyPublisher<[Status], Error> {
        ValueObservation
            .tracking(timeline.statuses
                        .including(required: StoredStatus.account)
                        .including(optional: StoredStatus.reblogAccount)
                        .including(optional: StoredStatus.reblog)
                        .asRequest(of: StatusResult.self)
                        .fetchAll)
            .removeDuplicates()
            .publisher(in: databaseQueue)
            .map { $0.map(Status.init(statusResult:)) }
            .eraseToAnyPublisher()
    }

    func statusesObservation(collection: TransientStatusCollection) -> AnyPublisher<[Status], Error> {
        ValueObservation.tracking {
            try StatusResult.fetchAll(
                $0,
                StoredStatus.filter(
                    try collection
                        .elements
                        .fetchAll($0)
                        .map(\.statusId)
                        .contains(Column("id")))
                    .including(required: StoredStatus.account)
                    .including(optional: StoredStatus.reblogAccount)
                    .including(optional: StoredStatus.reblog))
        }
        .removeDuplicates()
        .publisher(in: databaseQueue)
        .map { $0.map(Status.init(statusResult:)) }
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

    func filtersObservation() -> AnyPublisher<[Filter], Error> {
        ValueObservation.tracking(Filter.fetchAll)
            .removeDuplicates()
            .publisher(in: databaseQueue)
            .eraseToAnyPublisher()
    }
}

private extension ContentDatabase {
    static var attributedStringCache: AttributedStringCache?

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

    static func createTemporaryTables(_ writer: DatabaseWriter) throws {
        try writer.write { database in
            try database.create(table: "transientStatusCollection", temporary: true, ifNotExists: true) { t in
                t.column("id", .text).notNull().primaryKey(onConflict: .replace)
            }

            try database.create(table: "transientStatusCollectionElement", temporary: true, ifNotExists: true) { t in
                t.column("transientStatusCollectionId", .text)
                    .notNull()
                    .references("transientStatusCollection", column: "id", onDelete: .cascade, onUpdate: .cascade)
                t.column("statusId", .text).notNull()

                t.primaryKey(["transientStatusCollectionId", "statusId"], onConflict: .replace)
            }
        }
    }
}

extension Account: TableRecord, FetchableRecord, PersistableRecord {
    static var databaseDecodingUserInfo: [CodingUserInfoKey: Any] {
        var userInfo = [CodingUserInfoKey: Any]()

        if let attributedStringCache = ContentDatabase.attributedStringCache {
            userInfo[.attributedStringCache] = attributedStringCache
        }

        return userInfo
    }

    static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        MastodonDecoder()
    }

    static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        MastodonEncoder()
    }
}

protocol StatusCollection: FetchableRecord, PersistableRecord {
    var id: String { get }

    func joinRecord(status: Status) -> PersistableRecord
}

private struct TimelineStatusJoin: Codable, TableRecord, FetchableRecord, PersistableRecord {
    let timelineId: String
    let statusId: String

    static let status = belongsTo(StoredStatus.self)
}

extension Timeline: StatusCollection {
    enum Columns: String, ColumnExpression {
        case id, listTitle
    }

    init(row: Row) {
        switch row[Columns.id] as String {
        case Timeline.home.id:
            self = .home
        case Timeline.local.id:
            self = .local
        case Timeline.federated.id:
            self = .federated
        default:
            self = .list(MastodonList(id: row[Columns.id], title: row[Columns.listTitle]))
        }
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id

        if case let .list(list) = self {
            container[Columns.listTitle] = list.title
        }
    }

    func joinRecord(status: Status) -> PersistableRecord {
        TimelineStatusJoin(timelineId: id, statusId: status.id)
    }
}

private extension Timeline {
    static let statusJoins = hasMany(TimelineStatusJoin.self)

    static let statuses = hasMany(StoredStatus.self,
                                  through: statusJoins,
                                  using: TimelineStatusJoin.status).order(Column("createdAt").desc)

    var statusJoins: QueryInterfaceRequest<TimelineStatusJoin> {
        request(for: Self.statusJoins)
    }

    var statuses: QueryInterfaceRequest<StoredStatus> {
        request(for: Self.statuses)
    }
}

extension Filter: TableRecord, FetchableRecord, PersistableRecord {
    static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        MastodonDecoder()
    }

    static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        MastodonEncoder()
    }
}

private struct TransientStatusCollectionElement: Codable, TableRecord, FetchableRecord, PersistableRecord {
    let transientStatusCollectionId: String
    let statusId: String

    static let status = belongsTo(StoredStatus.self, key: "statusId")
}

extension TransientStatusCollection: StatusCollection {
    func joinRecord(status: Status) -> PersistableRecord {
        TransientStatusCollectionElement(transientStatusCollectionId: id, statusId: status.id)
    }
}

private extension TransientStatusCollection {
    static let elements = hasMany(TransientStatusCollectionElement.self)

    var elements: QueryInterfaceRequest<TransientStatusCollectionElement> {
        request(for: Self.elements)
    }
}

private struct StoredStatus: Codable, Hashable {
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

extension StoredStatus: TableRecord, FetchableRecord, PersistableRecord {
    static var databaseDecodingUserInfo: [CodingUserInfoKey: Any] {
        var userInfo = [CodingUserInfoKey: Any]()

        if let attributedStringCache = ContentDatabase.attributedStringCache {
            userInfo[.attributedStringCache] = attributedStringCache
        }

        return userInfo
    }

    static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        MastodonDecoder()
    }

    static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        MastodonEncoder()
    }
}

private struct StatusResult: Codable, Hashable, FetchableRecord {
    let account: Account
    let status: StoredStatus
    let reblogAccount: Account?
    let reblog: StoredStatus?
}

private extension Status {
    func storedComponents() -> [PersistableRecord] {
        var components: [PersistableRecord] = [account]

        if let reblog = reblog {
            components.append(reblog.account)
            components.append(StoredStatus(status: reblog))
        }

        components.append(StoredStatus(status: self))

        return components
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
