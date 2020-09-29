// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct TimelineStatusJoin: Codable, FetchableRecord, PersistableRecord {
    let timelineId: String
    let statusId: String

    static let status = belongsTo(StatusRecord.self)
}

extension TimelineStatusJoin {
    enum Columns {
        static let timelineId = Column(TimelineStatusJoin.CodingKeys.timelineId)
        static let statusId = Column(TimelineStatusJoin.CodingKeys.statusId)
    }
}
