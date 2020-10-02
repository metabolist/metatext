// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

public struct LoadMore: Codable, Hashable {
    public let timelineId: String
    public let afterStatusId: String
}

extension LoadMore: FetchableRecord, PersistableRecord {
    public static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        MastodonDecoder()
    }

    public static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        MastodonEncoder()
    }
}

extension LoadMore {
    enum Columns {
        static let timelineId = Column(LoadMore.CodingKeys.timelineId)
        static let belowStatusId = Column(LoadMore.CodingKeys.afterStatusId)
    }
}
