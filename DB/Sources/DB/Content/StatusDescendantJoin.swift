// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct StatusDescendantJoin: Codable, FetchableRecord, PersistableRecord {
    let parentId: String
    let statusId: String
    let index: Int

    static let status = belongsTo(StatusRecord.self, using: ForeignKey([Columns.statusId]))
}

extension StatusDescendantJoin {
    enum Columns {
        static let parentId = Column(StatusDescendantJoin.CodingKeys.parentId)
        static let statusId = Column(StatusDescendantJoin.CodingKeys.statusId)
        static let index = Column(StatusDescendantJoin.CodingKeys.index)
    }
}
