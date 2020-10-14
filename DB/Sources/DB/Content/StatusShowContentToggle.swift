// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct StatusShowContentToggle: Codable, Hashable {
    let statusId: Status.Id
}

extension StatusShowContentToggle {
    enum Columns {
        static let statusId = Column(StatusShowContentToggle.CodingKeys.statusId)
    }
}

extension StatusShowContentToggle: FetchableRecord, PersistableRecord {
    static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        MastodonDecoder()
    }

    static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        MastodonEncoder()
    }
}
