// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct AccountPinnedStatusJoin: ContentDatabaseRecord {
    let accountId: Account.Id
    let statusId: Status.Id
    let order: Int
}

extension AccountPinnedStatusJoin {
    enum Columns {
        static let accountId = Column(CodingKeys.accountId)
        static let statusId = Column(CodingKeys.statusId)
        static let order = Column(CodingKeys.order)
    }

    static let status = belongsTo(StatusRecord.self)
}
