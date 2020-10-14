// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Filter: ContentDatabaseRecord {}

extension Filter {
    enum Columns: String, ColumnExpression {
        case id
        case phrase
        case context
        case expiresAt
        case irreversible
        case wholeWord
    }
}

extension Array where Element == StatusInfo {
    func filtered(regularExpression: String?) -> Self {
        guard let regEx = regularExpression else { return self }

        return filter { $0.filterableContent.range(of: regEx, options: [.regularExpression, .caseInsensitive]) == nil }
    }
}
