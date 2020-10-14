// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

protocol ContentDatabaseRecord: Codable, FetchableRecord, PersistableRecord {}

extension ContentDatabaseRecord {
    public static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        MastodonDecoder()
    }

    public static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        ContentDatabaseJSONEncoder()
    }
}
