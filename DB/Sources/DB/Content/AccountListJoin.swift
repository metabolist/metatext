// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct AccountListJoin: Codable, FetchableRecord, PersistableRecord {
    let accountId: String
    let listId: UUID
    let index: Int

    static let account = belongsTo(AccountRecord.self, using: ForeignKey([Column("accountId")]))
}
