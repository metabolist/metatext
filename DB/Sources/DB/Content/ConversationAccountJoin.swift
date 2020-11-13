// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct ConversationAccountJoin: ContentDatabaseRecord {
    let conversationId: Conversation.Id
    let accountId: Account.Id
}

extension ConversationAccountJoin {
    enum Columns {
        static let conversationId = Column(CodingKeys.conversationId)
        static let accountId = Column(CodingKeys.accountId)
    }

    static let account = belongsTo(AccountRecord.self)
}
