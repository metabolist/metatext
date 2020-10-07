// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct StatusShowMoreToggle: Codable, Hashable {
    let statusId: Status.Id
}

extension StatusShowMoreToggle {
    enum Columns {
        static let statusId = Column(StatusShowMoreToggle.CodingKeys.statusId)
    }
}

extension StatusShowMoreToggle: FetchableRecord, PersistableRecord {
    static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        MastodonDecoder()
    }

    static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        MastodonEncoder()
    }
}
