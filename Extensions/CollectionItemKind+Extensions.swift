// Copyright © 2020 Metabolist. All rights reserved.

import ViewModels

extension CollectionItem.Kind {
    var cellClass: AnyClass {
        switch self {
        case .status:
            return StatusListCell.self
        case .account:
            return AccountListCell.self
        }
    }
}
