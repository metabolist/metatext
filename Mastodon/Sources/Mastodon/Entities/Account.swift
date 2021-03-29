// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public final class Account: Codable, Identifiable {
    public let id: Id
    public let username: String
    public let acct: String
    public let displayName: String
    public let locked: Bool
    public let createdAt: Date
    public let followersCount: Int
    public let followingCount: Int
    public let statusesCount: Int
    public let note: HTML
    public let url: String
    public let avatar: UnicodeURL
    public let avatarStatic: UnicodeURL
    public let header: UnicodeURL
    public let headerStatic: UnicodeURL
    public let fields: [Field]
    public let emojis: [Emoji]
    @DecodableDefault.False public private(set) var bot: Bool
    @DecodableDefault.False public private(set) var discoverable: Bool
    public var moved: Account?
    public var source: Source?

    public init(id: Id,
                username: String,
                acct: String,
                displayName: String,
                locked: Bool,
                createdAt: Date,
                followersCount: Int,
                followingCount: Int,
                statusesCount: Int,
                note: HTML,
                url: String,
                avatar: UnicodeURL,
                avatarStatic: UnicodeURL,
                header: UnicodeURL,
                headerStatic: UnicodeURL,
                fields: [Account.Field],
                emojis: [Emoji],
                bot: Bool,
                discoverable: Bool,
                moved: Account?) {
        self.id = id
        self.username = username
        self.acct = acct
        self.displayName = displayName
        self.locked = locked
        self.createdAt = createdAt
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.statusesCount = statusesCount
        self.note = note
        self.url = url
        self.avatar = avatar
        self.avatarStatic = avatarStatic
        self.header = header
        self.headerStatic = headerStatic
        self.fields = fields
        self.emojis = emojis
        self.bot = bot
        self.discoverable = discoverable
        self.moved = moved
    }
}

public extension Account {
    typealias Id = String

    struct Field: Codable, Hashable {
        public let name: String
        public let value: HTML
        public let verifiedAt: Date?
    }

    struct Source: Codable, Hashable {
        public let note: String?
        public let fields: [Field]
        public let privacy: Status.Visibility?
        public let sensitive: Bool?
        public let language: String?
        public let followRequestsCount: Int?
    }
}

extension Account: Hashable {
    public static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.id == rhs.id &&
            lhs.username == rhs.username &&
            lhs.acct == rhs.acct &&
            lhs.displayName == rhs.displayName &&
            lhs.locked == rhs.locked &&
            lhs.createdAt == rhs.createdAt &&
            lhs.followersCount == rhs.followersCount &&
            lhs.followingCount == rhs.followingCount &&
            lhs.statusesCount == rhs.statusesCount &&
            lhs.note == rhs.note &&
            lhs.url == rhs.url &&
            lhs.avatar == rhs.avatar &&
            lhs.avatarStatic == rhs.avatarStatic &&
            lhs.header == rhs.header &&
            lhs.headerStatic == rhs.headerStatic &&
            lhs.fields == rhs.fields &&
            lhs.emojis == rhs.emojis &&
            lhs._bot == rhs._bot &&
            lhs._discoverable == rhs._discoverable &&
            lhs.moved == rhs.moved
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(username)
        hasher.combine(acct)
        hasher.combine(displayName)
        hasher.combine(locked)
        hasher.combine(createdAt)
        hasher.combine(followersCount)
        hasher.combine(followingCount)
        hasher.combine(statusesCount)
        hasher.combine(note)
        hasher.combine(url)
        hasher.combine(avatar)
        hasher.combine(avatarStatic)
        hasher.combine(header)
        hasher.combine(headerStatic)
        hasher.combine(fields)
        hasher.combine(emojis)
        hasher.combine(bot)
        hasher.combine(discoverable)
        hasher.combine(moved)
    }
}
