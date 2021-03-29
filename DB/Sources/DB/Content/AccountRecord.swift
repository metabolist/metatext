// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct AccountRecord: ContentDatabaseRecord, Hashable {
    let id: Account.Id
    let username: String
    let acct: String
    let displayName: String
    let locked: Bool
    let createdAt: Date
    let followersCount: Int
    let followingCount: Int
    let statusesCount: Int
    let note: HTML
    let url: String
    let avatar: UnicodeURL
    let avatarStatic: UnicodeURL
    let header: UnicodeURL
    let headerStatic: UnicodeURL
    let fields: [Account.Field]
    let emojis: [Emoji]
    let bot: Bool
    let discoverable: Bool
    let movedId: Account.Id?
}

extension AccountRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let username = Column(CodingKeys.username)
        static let acct = Column(CodingKeys.acct)
        static let displayName = Column(CodingKeys.displayName)
        static let locked = Column(CodingKeys.locked)
        static let createdAt = Column(CodingKeys.createdAt)
        static let followersCount = Column(CodingKeys.followersCount)
        static let followingCount = Column(CodingKeys.followingCount)
        static let statusesCount = Column(CodingKeys.statusesCount)
        static let note = Column(CodingKeys.note)
        static let url = Column(CodingKeys.url)
        static let avatar = Column(CodingKeys.avatar)
        static let avatarStatic = Column(CodingKeys.avatarStatic)
        static let header = Column(CodingKeys.header)
        static let headerStatic = Column(CodingKeys.headerStatic)
        static let fields = Column(CodingKeys.fields)
        static let emojis = Column(CodingKeys.emojis)
        static let bot = Column(CodingKeys.bot)
        static let discoverable = Column(CodingKeys.discoverable)
        static let movedId = Column(CodingKeys.movedId)
    }
}

extension AccountRecord {
    static let moved = belongsTo(AccountRecord.self)
    static let relationship = hasOne(Relationship.self)
    static let identityProofs = hasMany(IdentityProofRecord.self)
    static let featuredTags = hasMany(FeaturedTagRecord.self)
    static let pinnedStatusJoins = hasMany(AccountPinnedStatusJoin.self)
        .order(AccountPinnedStatusJoin.Columns.order)
    static let pinnedStatuses = hasMany(
        StatusRecord.self,
        through: pinnedStatusJoins,
        using: AccountPinnedStatusJoin.status)

    var pinnedStatuses: QueryInterfaceRequest<StatusInfo> {
        StatusInfo.request(request(for: Self.pinnedStatuses))
    }

    init(account: Account) {
        id = account.id
        username = account.username
        acct = account.acct
        displayName = account.displayName
        locked = account.locked
        createdAt = account.createdAt
        followersCount = account.followersCount
        followingCount = account.followingCount
        statusesCount = account.statusesCount
        note = account.note
        url = account.url
        avatar = account.avatar
        avatarStatic = account.avatarStatic
        header = account.header
        headerStatic = account.headerStatic
        fields = account.fields
        emojis = account.emojis
        bot = account.bot
        discoverable = account.discoverable
        movedId = account.moved?.id
    }
}
