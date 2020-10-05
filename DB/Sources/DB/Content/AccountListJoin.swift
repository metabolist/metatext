// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct AccountListJoin: Codable, FetchableRecord, PersistableRecord {
    let accountId: Account.Id
    let listId: AccountList.Id
    let index: Int

    static let account = belongsTo(AccountRecord.self)
}

extension AccountListJoin {
    enum Columns {
        static let accountId = Column(AccountListJoin.CodingKeys.accountId)
        static let listId = Column(AccountListJoin.CodingKeys.listId)
        static let index = Column(AccountListJoin.CodingKeys.index)
    }
}
