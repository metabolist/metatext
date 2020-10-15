// Copyright © 2020 Metabolist. All rights reserved.

import ViewModels

extension CollectionItem {
    static let cellClasses = [StatusListCell.self, AccountListCell.self, LoadMoreCell.self]

    var cellClass: AnyClass {
        switch self {
        case .status:
            return StatusListCell.self
        case .account:
            return AccountListCell.self
        case .loadMore:
            return LoadMoreCell.self
        }
    }
}
