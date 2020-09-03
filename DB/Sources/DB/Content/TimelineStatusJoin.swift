// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct TimelineStatusJoin: Codable, FetchableRecord, PersistableRecord {
    let timelineId: String
    let statusId: String

    static let status = belongsTo(StoredStatus.self)
}
