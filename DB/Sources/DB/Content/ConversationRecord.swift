// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct ConversationRecord: ContentDatabaseRecord, Hashable {
    let id: Conversation.Id
    let unread: Bool
    let lastStatusId: Status.Id?
}

extension ConversationRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let unread = Column(CodingKeys.unread)
        static let lastStatusId = Column(CodingKeys.lastStatusId)
    }

    static let lastStatus = belongsTo(StatusRecord.self)
    static let accountJoins = hasMany(ConversationAccountJoin.self)
    static let accounts = hasMany(
        AccountRecord.self,
        through: accountJoins,
        using: ConversationAccountJoin.account)

    init(conversation: Conversation) {
        id = conversation.id
        unread = conversation.unread
        lastStatusId = conversation.lastStatus?.id
    }
}
