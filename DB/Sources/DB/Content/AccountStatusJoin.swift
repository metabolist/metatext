// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct AccountStatusJoin: Codable, FetchableRecord, PersistableRecord {
    let accountId: String
    let statusId: String
    let collection: AccountStatusCollection

    static let status = belongsTo(StatusRecord.self, using: ForeignKey([Column("statusId")]))
}
