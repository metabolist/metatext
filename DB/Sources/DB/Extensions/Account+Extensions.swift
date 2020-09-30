// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Account {
    func save(_ db: Database) throws {
        if let moved = moved {
            try AccountRecord(account: moved).save(db)
        }

        try AccountRecord(account: self).save(db)
    }

    convenience init(info: AccountInfo) {
        var moved: Account?

        if let movedRecord = info.movedRecord {
            moved = Self(record: movedRecord, moved: nil)
        }

        self.init(record: info.record, moved: moved)
    }
}

private extension Account {
    convenience init(record: AccountRecord, moved: Account?) {
        self.init(id: record.id,
                  username: record.username,
                  acct: record.acct,
                  displayName: record.displayName,
                  locked: record.locked,
                  createdAt: record.createdAt,
                  followersCount: record.followersCount,
                  followingCount: record.followingCount,
                  statusesCount: record.statusesCount,
                  note: record.note,
                  url: record.url,
                  avatar: record.avatar,
                  avatarStatic: record.avatarStatic,
                  header: record.header,
                  headerStatic: record.headerStatic,
                  fields: record.fields,
                  emojis: record.emojis,
                  bot: record.bot,
                  discoverable: record.discoverable,
                  moved: moved)
    }
}
