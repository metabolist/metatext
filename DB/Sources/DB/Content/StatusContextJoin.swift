// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct StatusContextJoin: Codable, FetchableRecord, PersistableRecord {
    enum Section: String, Codable {
        case ancestors
        case descendants
    }

    let parentId: String
    let statusId: String
    let section: Section
    let index: Int

    static let status = belongsTo(StatusRecord.self, using: ForeignKey([Columns.statusId]))
}

extension StatusContextJoin {
    enum Columns {
        static let parentId = Column(StatusContextJoin.CodingKeys.parentId)
        static let statusId = Column(StatusContextJoin.CodingKeys.statusId)
        static let section = Column(StatusContextJoin.CodingKeys.section)
        static let index = Column(StatusContextJoin.CodingKeys.index)
    }
}
