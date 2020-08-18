// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class Status: Codable, Identifiable {
    enum Visibility: String, Codable, Unknowable {
        case `public`
        case unlisted
        case `private`
        case direct
        case unknown

        static var unknownCase: Self { .unknown }
    }

    let id: String
    let uri: String
    let createdAt: Date
    let account: Account
    let content: String
    let visibility: Visibility
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
    let reblog: Status?
    let poll: Poll?
    let card: Card?
    let language: String?
    let text: String?
    let favourited: Bool?
    let reblogged: Bool?
    let muted: Bool?
    let bookmarked: Bool?
    let pinned: Bool?

    // Xcode-generated memberwise initializer
    init(
        id: String,
        uri: String,
        createdAt: Date,
        account: Account,
        content: String,
        visibility: Status.Visibility,
        sensitive: Bool,
        spoilerText: String,
        mediaAttachments: [Attachment],
        mentions: [Mention],
        tags: [Tag],
        emojis: [Emoji],
        reblogsCount: Int,
        favouritesCount: Int,
        repliesCount: Int,
        application: Application?,
        url: URL?,
        inReplyToId: String?,
        inReplyToAccountId: String?,
        reblog: Status?,
        poll: Poll?,
        card: Card?,
        language: String?,
        text: String?,
        favourited: Bool?,
        reblogged: Bool?,
        muted: Bool?,
        bookmarked: Bool?,
        pinned: Bool?) {
        self.id = id
        self.uri = uri
        self.createdAt = createdAt
        self.account = account
        self.content = content
        self.visibility = visibility
        self.sensitive = sensitive
        self.spoilerText = spoilerText
        self.mediaAttachments = mediaAttachments
        self.mentions = mentions
        self.tags = tags
        self.emojis = emojis
        self.reblogsCount = reblogsCount
        self.favouritesCount = favouritesCount
        self.repliesCount = repliesCount
        self.application = application
        self.url = url
        self.inReplyToId = inReplyToId
        self.inReplyToAccountId = inReplyToAccountId
        self.reblog = reblog
        self.poll = poll
        self.card = card
        self.language = language
        self.text = text
        self.favourited = favourited
        self.reblogged = reblogged
        self.muted = muted
        self.bookmarked = bookmarked
        self.pinned = pinned
    }
}
