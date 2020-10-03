// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct StatusAncestorJoin: Codable, FetchableRecord, PersistableRecord {
    let parentId: String
    let statusId: String
    let index: Int

    static let status = belongsTo(StatusRecord.self, using: ForeignKey([Columns.statusId]))
}

extension StatusAncestorJoin {
    enum Columns {
        static let parentId = Column(StatusAncestorJoin.CodingKeys.parentId)
        static let statusId = Column(StatusAncestorJoin.CodingKeys.statusId)
        static let index = Column(StatusAncestorJoin.CodingKeys.index)
    }
}
