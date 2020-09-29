// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct AccountStatusJoin: Codable, FetchableRecord, PersistableRecord {
    let accountId: String
    let statusId: String
    let collection: ProfileCollection

    static let status = belongsTo(StatusRecord.self, using: ForeignKey([Columns.statusId]))
}

extension AccountStatusJoin {
    enum Columns {
        static let accountId = Column(AccountStatusJoin.CodingKeys.accountId)
        static let statusId = Column(AccountStatusJoin.CodingKeys.statusId)
        static let collection = Column(AccountStatusJoin.CodingKeys.collection)
    }
}
