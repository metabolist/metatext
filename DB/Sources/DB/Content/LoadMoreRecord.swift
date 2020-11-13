// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct LoadMoreRecord: ContentDatabaseRecord, Hashable {
    let timelineId: Timeline.Id
    let afterStatusId: Status.Id
    let beforeStatusId: Status.Id
}

extension LoadMoreRecord {
    enum Columns {
        static let timelineId = Column(CodingKeys.timelineId)
        static let afterStatusId = Column(CodingKeys.afterStatusId)
        static let beforeStatusId = Column(CodingKeys.beforeStatusId)
    }
}
