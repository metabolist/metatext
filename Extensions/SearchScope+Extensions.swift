// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import ViewModels

extension SearchScope {
    var title: String {
        switch self {
        case .all:
            return NSLocalizedString("search.scope.all", comment: "")
        case .accounts:
            return NSLocalizedString("search.scope.accounts", comment: "")
        case .statuses:
            return NSLocalizedString("search.scope.statuses", comment: "")
        case .tags:
            return NSLocalizedString("search.scope.tags", comment: "")
        }
    }

    var moreDescription: String? {
        switch self {
        case .all:
            return nil
        case .accounts:
            return NSLocalizedString("more-results.accounts", comment: "")
        case .statuses:
            return NSLocalizedString("more-results.statuses", comment: "")
        case .tags:
            return NSLocalizedString("more-results.tags", comment: "")
        }
    }
}
