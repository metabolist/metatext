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
    let content: HTML
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
        content: HTML,
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

extension Status {
    var displayStatus: Status {
        reblog ?? self
    }
}

extension Status: Hashable {
    static func == (lhs: Status, rhs: Status) -> Bool {
        lhs.id == rhs.id
            && lhs.uri == rhs.uri
            && lhs.createdAt == rhs.createdAt
            && lhs.account == rhs.account
            && lhs.content == rhs.content
            && lhs.visibility == rhs.visibility
            && lhs.sensitive == rhs.sensitive
            && lhs.spoilerText == rhs.spoilerText
            && lhs.mediaAttachments == rhs.mediaAttachments
            && lhs.mentions == rhs.mentions
            && lhs.tags == rhs.tags
            && lhs.emojis == rhs.emojis
            && lhs.reblogsCount == rhs.reblogsCount
            && lhs.favouritesCount == rhs.favouritesCount
            && lhs.repliesCount == rhs.repliesCount
            && lhs.application == rhs.application
            && lhs.url == rhs.url
            && lhs.inReplyToId == rhs.inReplyToId
            && lhs.inReplyToAccountId == rhs.inReplyToAccountId
            && lhs.reblog == rhs.reblog
            && lhs.poll == rhs.poll
            && lhs.card == rhs.card
            && lhs.language == rhs.language
            && lhs.text == rhs.text
            && lhs.favourited == rhs.favourited
            && lhs.reblogged == rhs.reblogged
            && lhs.muted == rhs.muted
            && lhs.bookmarked == rhs.bookmarked
            && lhs.pinned == rhs.pinned
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(uri)
        hasher.combine(createdAt)
        hasher.combine(account)
        hasher.combine(content)
        hasher.combine(visibility)
        hasher.combine(sensitive)
        hasher.combine(spoilerText)
        hasher.combine(mediaAttachments)
        hasher.combine(mentions)
        hasher.combine(tags)
        hasher.combine(emojis)
        hasher.combine(reblogsCount)
        hasher.combine(favouritesCount)
        hasher.combine(repliesCount)
        hasher.combine(application)
        hasher.combine(url)
        hasher.combine(inReplyToId)
        hasher.combine(inReplyToAccountId)
        hasher.combine(reblog)
        hasher.combine(poll)
        hasher.combine(card)
        hasher.combine(language)
        hasher.combine(text)
        hasher.combine(favourited)
        hasher.combine(reblogged)
        hasher.combine(muted)
        hasher.combine(bookmarked)
        hasher.combine(pinned)
    }
}
