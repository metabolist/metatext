// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Conversation {
    func save(_ db: Database) throws {
        guard let lastStatus = lastStatus else { return }

        try lastStatus.save(db)
        try ConversationRecord(conversation: self).save(db)

        for account in accounts {
            try account.save(db)
            try ConversationAccountJoin(conversationId: id, accountId: account.id).save(db)
        }
    }

    init(info: ConversationInfo) {
        self.init(
            id: info.record.id,
            accounts: info.accountInfos.map(Account.init(info:)),
            unread: info.record.unread,
        lastStatus: Status(info: info.lastStatusInfo))
    }
}
