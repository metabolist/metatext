// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct StatusRecord: Codable, Hashable {
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

extension StatusRecord {
    enum Columns {
        static let id = Column(StatusRecord.CodingKeys.id)
        static let uri = Column(StatusRecord.CodingKeys.uri)
        static let createdAt = Column(StatusRecord.CodingKeys.createdAt)
        static let accountId = Column(StatusRecord.CodingKeys.accountId)
        static let content = Column(StatusRecord.CodingKeys.content)
        static let visibility = Column(StatusRecord.CodingKeys.visibility)
        static let sensitive = Column(StatusRecord.CodingKeys.sensitive)
        static let spoilerText = Column(StatusRecord.CodingKeys.spoilerText)
        static let mediaAttachments = Column(StatusRecord.CodingKeys.mediaAttachments)
        static let mentions = Column(StatusRecord.CodingKeys.mentions)
        static let tags = Column(StatusRecord.CodingKeys.tags)
        static let emojis = Column(StatusRecord.CodingKeys.emojis)
        static let reblogsCount = Column(StatusRecord.CodingKeys.reblogsCount)
        static let favouritesCount = Column(StatusRecord.CodingKeys.favouritesCount)
        static let repliesCount = Column(StatusRecord.CodingKeys.repliesCount)
        static let application = Column(StatusRecord.CodingKeys.application)
        static let url = Column(StatusRecord.CodingKeys.url)
        static let inReplyToId = Column(StatusRecord.CodingKeys.inReplyToId)
        static let inReplyToAccountId = Column(StatusRecord.CodingKeys.inReplyToAccountId)
        static let reblogId = Column(StatusRecord.CodingKeys.reblogId)
        static let poll = Column(StatusRecord.CodingKeys.poll)
        static let card = Column(StatusRecord.CodingKeys.card)
        static let language = Column(StatusRecord.CodingKeys.language)
        static let text = Column(StatusRecord.CodingKeys.text)
        static let favourited = Column(StatusRecord.CodingKeys.favourited)
        static let reblogged = Column(StatusRecord.CodingKeys.reblogged)
        static let muted = Column(StatusRecord.CodingKeys.muted)
        static let bookmarked = Column(StatusRecord.CodingKeys.bookmarked)
        static let pinned = Column(StatusRecord.CodingKeys.pinned)
    }
}

extension StatusRecord: FetchableRecord, PersistableRecord {
    static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        MastodonDecoder()
    }

    static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        MastodonEncoder()
    }
}

extension StatusRecord {
    static let account = belongsTo(AccountRecord.self)
    static let accountMoved = hasOne(AccountRecord.self,
                                     through: Self.account,
                                     using: AccountRecord.moved)
    static let reblogAccount = hasOne(AccountRecord.self,
                                      through: Self.reblog,
                                      using: Self.account)
    static let reblogAccountMoved = hasOne(AccountRecord.self,
                                           through: Self.reblogAccount,
                                           using: AccountRecord.moved)
    static let reblog = belongsTo(StatusRecord.self)
    static let ancestorJoins = hasMany(
        StatusAncestorJoin.self,
        using: ForeignKey([StatusAncestorJoin.Columns.parentId]))
        .order(StatusAncestorJoin.Columns.index)
    static let descendantJoins = hasMany(
        StatusDescendantJoin.self,
        using: ForeignKey([StatusDescendantJoin.Columns.parentId]))
        .order(StatusDescendantJoin.Columns.index)
    static let ancestors = hasMany(StatusRecord.self,
                                   through: ancestorJoins,
                                   using: StatusAncestorJoin.status)
    static let descendants = hasMany(StatusRecord.self,
                                   through: descendantJoins,
                                   using: StatusDescendantJoin.status)

    var ancestors: QueryInterfaceRequest<StatusInfo> {
        StatusInfo.request(request(for: Self.ancestors))
    }

    var descendants: QueryInterfaceRequest<StatusInfo> {
        StatusInfo.request(request(for: Self.descendants))
    }

    var filterableContent: [String] {
        [content.attributed.string, spoilerText] + (poll?.options.map(\.title) ?? [])
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
