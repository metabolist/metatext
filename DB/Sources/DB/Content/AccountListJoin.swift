// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct AccountListJoin: ContentDatabaseRecord {
    let accountListId: AccountList.Id
    let accountId: Account.Id
    let order: Int

    static let account = belongsTo(AccountRecord.self)
}

extension AccountListJoin {
    enum Columns {
        static let accountListId = Column(CodingKeys.accountListId)
        static let accountId = Column(CodingKeys.accountId)
        static let order = Column(CodingKeys.order)
    }
}
