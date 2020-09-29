// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct AccountPinnedStatusJoin: Codable, FetchableRecord, PersistableRecord {
    let accountId: String
    let statusId: String
    let index: Int

    static let status = belongsTo(StatusRecord.self)
}

extension AccountPinnedStatusJoin {
    enum Columns {
        static let accountId = Column(AccountPinnedStatusJoin.CodingKeys.accountId)
        static let statusId = Column(AccountPinnedStatusJoin.CodingKeys.statusId)
        static let index = Column(AccountPinnedStatusJoin.CodingKeys.index)
    }
}
