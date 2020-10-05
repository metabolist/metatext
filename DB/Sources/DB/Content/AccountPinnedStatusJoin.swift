// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct AccountPinnedStatusJoin: Codable, FetchableRecord, PersistableRecord {
    let accountId: Account.Id
    let statusId: Status.Id
    let index: Int
}

extension AccountPinnedStatusJoin {
    enum Columns {
        static let accountId = Column(AccountPinnedStatusJoin.CodingKeys.accountId)
        static let statusId = Column(AccountPinnedStatusJoin.CodingKeys.statusId)
        static let index = Column(AccountPinnedStatusJoin.CodingKeys.index)
    }

    static let status = belongsTo(StatusRecord.self)
}
