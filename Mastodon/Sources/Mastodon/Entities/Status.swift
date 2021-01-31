// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public final class Status: Codable, Identifiable {
    public enum Visibility: String, Codable, Unknowable {
        case `public`
        case unlisted
        case `private`
        case direct
        case unknown

        public static var unknownCase: Self { .unknown }
    }

    public let id: Status.Id
    public let uri: String
    public let createdAt: Date
    public let account: Account
    @DecodableDefault.EmptyHTML public private(set) var content: HTML
    public let visibility: Visibility
    public let sensitive: Bool
    public let spoilerText: String
    public let mediaAttachments: [Attachment]
    public let mentions: [Mention]
    public let tags: [Tag]
    public let emojis: [Emoji]
    public let reblogsCount: Int
    public let favouritesCount: Int
    @DecodableDefault.Zero public private(set) var repliesCount: Int
    public let application: Application?
    public let url: String?
    public let inReplyToId: Status.Id?
    public let inReplyToAccountId: Account.Id?
    public let reblog: Status?
    public let poll: Poll?
    public let card: Card?
    public let language: String?
    public let text: String?
    @DecodableDefault.False public private(set) var favourited: Bool
    @DecodableDefault.False public private(set) var reblogged: Bool
    @DecodableDefault.False public private(set) var muted: Bool
    @DecodableDefault.False public private(set) var bookmarked: Bool
    public let pinned: Bool?

    public init(
        id: Status.Id,
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
        url: String?,
        inReplyToId: Status.Id?,
        inReplyToAccountId: Account.Id?,
        reblog: Status?,
        poll: Poll?,
        card: Card?,
        language: String?,
        text: String?,
        favourited: Bool,
        reblogged: Bool,
        muted: Bool,
        bookmarked: Bool,
        pinned: Bool?) {
        self.id = id
        self.uri = uri
        self.createdAt = createdAt
        self.account = account
        self.visibility = visibility
        self.sensitive = sensitive
        self.spoilerText = spoilerText
        self.mediaAttachments = mediaAttachments
        self.mentions = mentions
        self.tags = tags
        self.emojis = emojis
        self.reblogsCount = reblogsCount
        self.favouritesCount = favouritesCount
        self.application = application
        self.url = url
        self.inReplyToId = inReplyToId
        self.inReplyToAccountId = inReplyToAccountId
        self.reblog = reblog
        self.poll = poll
        self.card = card
        self.language = language
        self.text = text
        self.pinned = pinned
        self.repliesCount = repliesCount
        self.content = content
        self.favourited = favourited
        self.reblogged = reblogged
        self.muted = muted
        self.bookmarked = bookmarked
    }
}

public extension Status {
    typealias Id = String

    var displayStatus: Status {
        reblog ?? self
    }
}

extension Status: Hashable {
    public static func == (lhs: Status, rhs: Status) -> Bool {
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

    public func hash(into hasher: inout Hasher) {
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
