// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct TimelineStatusJoin: ContentDatabaseRecord {
    let timelineId: Timeline.Id
    let statusId: Status.Id

    static let status = belongsTo(StatusRecord.self)
}

extension TimelineStatusJoin {
    enum Columns {
        static let timelineId = Column(TimelineStatusJoin.CodingKeys.timelineId)
        static let statusId = Column(TimelineStatusJoin.CodingKeys.statusId)
    }
}
