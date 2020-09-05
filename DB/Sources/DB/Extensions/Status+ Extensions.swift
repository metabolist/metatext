// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Status {
    func save(_ db: Database) throws {
        try account.save(db)

        if let reblog = reblog {
            try reblog.account.save(db)
            try StatusRecord(status: reblog).save(db)
        }

        try StatusRecord(status: self).save(db)
    }

    convenience init(result: StatusResult) {
        var reblog: Status?

        if let reblogResult = result.reblog, let reblogAccountResult = result.reblogAccountResult {
            reblog = Status(record: reblogResult, account: Account(result: reblogAccountResult), reblog: nil)
        }

        self.init(record: result.status,
                  account: Account(result: result.accountResult),
                  reblog: reblog)
    }
}

private extension Status {
    convenience init(record: StatusRecord, account: Account, reblog: Status?) {
        self.init(
            id: record.id,
            uri: record.uri,
            createdAt: record.createdAt,
            account: account,
            content: record.content,
            visibility: record.visibility,
            sensitive: record.sensitive,
            spoilerText: record.spoilerText,
            mediaAttachments: record.mediaAttachments,
            mentions: record.mentions,
            tags: record.tags,
            emojis: record.emojis,
            reblogsCount: record.reblogsCount,
            favouritesCount: record.favouritesCount,
            repliesCount: record.repliesCount,
            application: record.application,
            url: record.url,
            inReplyToId: record.inReplyToId,
            inReplyToAccountId: record.inReplyToAccountId,
            reblog: reblog,
            poll: record.poll,
            card: record.card,
            language: record.language,
            text: record.text,
            favourited: record.favourited,
            reblogged: record.reblogged,
            muted: record.muted,
            bookmarked: record.bookmarked,
            pinned: record.pinned)
    }
}
