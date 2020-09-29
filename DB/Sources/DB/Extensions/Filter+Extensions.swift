// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Filter: FetchableRecord, PersistableRecord {
    enum Columns: String, ColumnExpression {
        case id
        case phrase
        case context
        case expiresAt
        case irreversible
        case wholeWord
    }

    public static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        MastodonDecoder()
    }

    public static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        MastodonEncoder()
    }
}
