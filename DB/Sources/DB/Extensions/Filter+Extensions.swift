// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Filter: FetchableRecord, PersistableRecord {
    public static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        APIDecoder()
    }

    public static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        APIEncoder()
    }
}
