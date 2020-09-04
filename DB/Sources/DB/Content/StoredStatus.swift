// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

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

extension StoredStatus: FetchableRecord, PersistableRecord {
    static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        MastodonDecoder()
    }

    static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        MastodonEncoder()
    }
}

extension StoredStatus {
    static let account = belongsTo(Account.self, key: "account")
    static let reblogAccount = hasOne(Account.self, through: Self.reblog, using: Self.account, key: "reblogAccount")
    static let reblog = belongsTo(StoredStatus.self, key: "reblog")
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

    var account: QueryInterfaceRequest<Account> {
        request(for: Self.account)
    }

    var reblogAccount: QueryInterfaceRequest<Account> {
        request(for: Self.reblogAccount)
    }

    var reblog: QueryInterfaceRequest<StoredStatus> {
        request(for: Self.reblog)
    }

    var ancestors: QueryInterfaceRequest<StatusResult> {
        request(for: Self.ancestors).statusResultRequest
    }

    var descendants: QueryInterfaceRequest<StatusResult> {
        request(for: Self.descendants).statusResultRequest
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
