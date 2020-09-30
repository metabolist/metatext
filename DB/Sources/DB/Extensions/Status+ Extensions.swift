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

    convenience init(info: StatusInfo) {
        var reblog: Status?

        if let reblogRecord = info.reblogRecord, let reblogAccountInfo = info.reblogAccountInfo {
            reblog = Status(record: reblogRecord, account: Account(info: reblogAccountInfo), reblog: nil)
        }

        self.init(record: info.record,
                  account: Account(info: info.accountInfo),
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
