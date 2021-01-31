// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct StatusAncestorJoin: ContentDatabaseRecord {
    let parentId: Status.Id
    let statusId: Status.Id
    let order: Int
}

extension StatusAncestorJoin {
    enum Columns {
        static let parentId = Column(CodingKeys.parentId)
        static let statusId = Column(CodingKeys.statusId)
        static let order = Column(CodingKeys.order)
    }

    static let status = belongsTo(StatusRecord.self, using: ForeignKey([Columns.statusId]))
}
