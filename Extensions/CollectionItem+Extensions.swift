// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

extension CollectionItem {
    static let cellClasses = [
        StatusListCell.self,
        AccountListCell.self,
        LoadMoreCell.self,
        NotificationListCell.self,
        ConversationListCell.self]

    var cellClass: AnyClass {
        switch self {
        case .status:
            return StatusListCell.self
        case .account:
            return AccountListCell.self
        case .loadMore:
            return LoadMoreCell.self
        case let .notification(_, statusConfiguration):
            return statusConfiguration == nil ? NotificationListCell.self : StatusListCell.self
        case .conversation:
            return ConversationListCell.self
        }
    }
}
