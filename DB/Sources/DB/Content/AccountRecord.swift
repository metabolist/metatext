// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct AccountRecord: Codable, Hashable {
    let id: String
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
    let movedId: String?
}

extension AccountRecord: FetchableRecord, PersistableRecord {
    static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        MastodonDecoder()
    }

    static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        MastodonEncoder()
    }
}

extension AccountRecord {
    static let moved = belongsTo(AccountRecord.self, key: "moved")

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
