// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Status {
    func save(_ db: Database) throws {
        try account.save(db)

        if let reblog = reblog {
            try reblog.account.save(db)
            try StoredStatus(status: reblog).save(db)
        }

        try StoredStatus(status: self).save(db)
    }

    convenience init(statusResult: StatusResult) {
        var reblog: Status?

        if let reblogResult = statusResult.reblog, let reblogAccount = statusResult.reblogAccount {
            reblog = Status(storedStatus: reblogResult, account: reblogAccount, reblog: nil)
        }

        self.init(storedStatus: statusResult.status, account: statusResult.account, reblog: reblog)
    }

    convenience init(storedStatus: StoredStatus, account: Account, reblog: Status?) {
        self.init(
            id: storedStatus.id,
            uri: storedStatus.uri,
            createdAt: storedStatus.createdAt,
            account: account,
            content: storedStatus.content,
            visibility: storedStatus.visibility,
            sensitive: storedStatus.sensitive,
            spoilerText: storedStatus.spoilerText,
            mediaAttachments: storedStatus.mediaAttachments,
            mentions: storedStatus.mentions,
            tags: storedStatus.tags,
            emojis: storedStatus.emojis,
            reblogsCount: storedStatus.reblogsCount,
            favouritesCount: storedStatus.favouritesCount,
            repliesCount: storedStatus.repliesCount,
            application: storedStatus.application,
            url: storedStatus.url,
            inReplyToId: storedStatus.inReplyToId,
            inReplyToAccountId: storedStatus.inReplyToAccountId,
            reblog: reblog,
            poll: storedStatus.poll,
            card: storedStatus.card,
            language: storedStatus.language,
            text: storedStatus.text,
            favourited: storedStatus.favourited,
            reblogged: storedStatus.reblogged,
            muted: storedStatus.muted,
            bookmarked: storedStatus.bookmarked,
            pinned: storedStatus.pinned)
    }
}
