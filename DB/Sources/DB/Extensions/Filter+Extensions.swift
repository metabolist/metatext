// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Filter: FetchableRecord, PersistableRecord {
    public static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        MastodonDecoder()
    }

    public static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        MastodonEncoder()
    }
}

extension Filter {
    enum Columns: String, ColumnExpression {
        case id
        case phrase
        case context
        case expiresAt
        case irreversible
        case wholeWord
    }

    static var active: QueryInterfaceRequest<Self> {
        filter(Filter.Columns.expiresAt == nil || Filter.Columns.expiresAt > Date())
    }
}

extension Array where Element == StatusInfo {
    func filtered(regularExpression: String?) -> Self {
        guard let regEx = regularExpression else { return self }

        return filter { $0.filterableContent.range(of: regEx, options: [.regularExpression, .caseInsensitive]) == nil }
    }
}
