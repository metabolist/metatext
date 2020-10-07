// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct StatusAncestorJoin: Codable, FetchableRecord, PersistableRecord {
    let parentId: Status.Id
    let statusId: Status.Id
    let index: Int
}

extension StatusAncestorJoin {
    enum Columns {
        static let parentId = Column(StatusAncestorJoin.CodingKeys.parentId)
        static let statusId = Column(StatusAncestorJoin.CodingKeys.statusId)
        static let index = Column(StatusAncestorJoin.CodingKeys.index)
    }

    static let status = belongsTo(StatusRecord.self, using: ForeignKey([Columns.statusId]))
}
