// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct TimelineStatusJoin: ContentDatabaseRecord {
    let timelineId: Timeline.Id
    let statusId: Status.Id
    let order: Int?

    static let status = belongsTo(StatusRecord.self)
}

extension TimelineStatusJoin {
    enum Columns {
        static let timelineId = Column(CodingKeys.timelineId)
        static let statusId = Column(CodingKeys.statusId)
        static let order = Column(CodingKeys.order)
    }
}
