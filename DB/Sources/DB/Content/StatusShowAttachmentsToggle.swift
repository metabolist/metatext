// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct StatusShowAttachmentsToggle: Codable, Hashable {
    let statusId: Status.Id
}

extension StatusShowAttachmentsToggle {
    enum Columns {
        static let statusId = Column(StatusShowAttachmentsToggle.CodingKeys.statusId)
    }
}

extension StatusShowAttachmentsToggle: FetchableRecord, PersistableRecord {
    static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        MastodonDecoder()
    }

    static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        MastodonEncoder()
    }
}
