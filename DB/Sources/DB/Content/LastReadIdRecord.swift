// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct LastReadIdRecord: ContentDatabaseRecord, Hashable {
    let markerTimeline: Marker.Timeline
    let id: String
}

extension LastReadIdRecord {
    enum Columns {
        static let markerTimeline = Column(LastReadIdRecord.CodingKeys.markerTimeline)
        static let id = Column(LastReadIdRecord.CodingKeys.id)
    }
}
