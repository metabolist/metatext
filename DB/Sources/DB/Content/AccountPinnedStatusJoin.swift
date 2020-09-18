// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct AccountPinnedStatusJoin: Codable, FetchableRecord, PersistableRecord {
    let accountId: String
    let statusId: String
    let index: Int

    static let status = belongsTo(StatusRecord.self, using: ForeignKey([Column("statusId")]))
}
