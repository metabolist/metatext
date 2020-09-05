// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Account {
    func save(_ db: Database) throws {
        if let moved = moved {
            try StoredAccount(account: moved).save(db)
        }

        try StoredAccount(account: self).save(db)
    }

    convenience init(accountResult: AccountResult) {
        var moved: Account?

        if let movedResult = accountResult.moved {
            moved = Self(storedAccount: movedResult, moved: nil)
        }

        self.init(storedAccount: accountResult.account, moved: moved)
    }

    convenience init(storedAccount: StoredAccount, moved: Account?) {
        self.init(id: storedAccount.id,
                  username: storedAccount.username,
                  acct: storedAccount.acct,
                  displayName: storedAccount.displayName,
                  locked: storedAccount.locked,
                  createdAt: storedAccount.createdAt,
                  followersCount: storedAccount.followersCount,
                  followingCount: storedAccount.followingCount,
                  statusesCount: storedAccount.statusesCount,
                  note: storedAccount.note,
                  url: storedAccount.url,
                  avatar: storedAccount.avatar,
                  avatarStatic: storedAccount.avatarStatic,
                  header: storedAccount.header,
                  headerStatic: storedAccount.headerStatic,
                  fields: storedAccount.fields,
                  emojis: storedAccount.emojis,
                  bot: storedAccount.bot,
                  discoverable: storedAccount.discoverable,
                  moved: moved)
    }
}
