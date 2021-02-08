// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct LastReadIdRecord: ContentDatabaseRecord, Hashable {
    let timelineId: Timeline.Id
    let id: String
}

extension LastReadIdRecord {
    enum Columns {
        static let timelineId = Column(CodingKeys.timelineId)
        static let id = Column(CodingKeys.id)
    }
}
