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
    let url: URL
    let avatar: URL
    let avatarStatic: URL
    let header: URL
    let headerStatic: URL
    let fields: [Account.Field]
    let emojis: [Emoji]
    let bot: Bool
    let discoverable: Bool
    let movedId: Account.Id?
}

extension AccountRecord {
    enum Columns {
        static let id = Column(AccountRecord.CodingKeys.id)
        static let username = Column(AccountRecord.CodingKeys.username)
        static let acct = Column(AccountRecord.CodingKeys.acct)
        static let displayName = Column(AccountRecord.CodingKeys.displayName)
        static let locked = Column(AccountRecord.CodingKeys.locked)
        static let createdAt = Column(AccountRecord.CodingKeys.createdAt)
        static let followersCount = Column(AccountRecord.CodingKeys.followersCount)
        static let followingCount = Column(AccountRecord.CodingKeys.followingCount)
        static let statusesCount = Column(AccountRecord.CodingKeys.statusesCount)
        static let note = Column(AccountRecord.CodingKeys.note)
        static let url = Column(AccountRecord.CodingKeys.url)
        static let avatar = Column(AccountRecord.CodingKeys.avatar)
        static let avatarStatic = Column(AccountRecord.CodingKeys.avatarStatic)
        static let header = Column(AccountRecord.CodingKeys.header)
        static let headerStatic = Column(AccountRecord.CodingKeys.headerStatic)
        static let fields = Column(AccountRecord.CodingKeys.fields)
        static let emojis = Column(AccountRecord.CodingKeys.emojis)
        static let bot = Column(AccountRecord.CodingKeys.bot)
        static let discoverable = Column(AccountRecord.CodingKeys.discoverable)
        static let movedId = Column(AccountRecord.CodingKeys.movedId)
    }
}

extension AccountRecord {
    static let moved = belongsTo(AccountRecord.self)
    static let pinnedStatusJoins = hasMany(AccountPinnedStatusJoin.self)
        .order(AccountPinnedStatusJoin.Columns.index)
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
