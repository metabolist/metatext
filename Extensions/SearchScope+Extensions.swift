// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import ViewModels

extension SearchScope {
    func title(statusWord: AppPreferences.StatusWord) -> String {
        switch self {
        case .all:
            return NSLocalizedString("search.scope.all", comment: "")
        case .accounts:
            return NSLocalizedString("search.scope.accounts", comment: "")
        case .statuses:
            switch statusWord {
            case .toot:
                return NSLocalizedString("search.scope.statuses.toot", comment: "")
            case .post:
                return NSLocalizedString("search.scope.statuses.post", comment: "")
            }
        case .tags:
            return NSLocalizedString("search.scope.tags", comment: "")
        }
    }

    func moreDescription(statusWord: AppPreferences.StatusWord) -> String? {
        switch self {
        case .all:
            return nil
        case .accounts:
            return NSLocalizedString("more-results.accounts", comment: "")
        case .statuses:
            switch statusWord {
            case .toot:
                return NSLocalizedString("more-results.statuses.toot", comment: "")
            case .post:
                return NSLocalizedString("more-results.statuses.post", comment: "")
            }

        case .tags:
            return NSLocalizedString("more-results.tags", comment: "")
        }
    }
}
