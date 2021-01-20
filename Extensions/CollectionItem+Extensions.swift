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

    func estimatedHeight(width: CGFloat, identification: Identification) -> CGFloat {
        switch self {
        case let .status(status, configuration):
            return StatusView.estimatedHeight(
                width: width,
                identification: identification,
                status: status,
                configuration: configuration)
        case let .account(account):
            return AccountView.estimatedHeight(width: width, account: account)
        case .loadMore:
            return LoadMoreView.estimatedHeight
        case let .notification(notification, configuration):
            return NotificationView.estimatedHeight(
                width: width,
                identification: identification,
                notification: notification,
                configuration: configuration)
        case let .conversation(conversation):
            return ConversationView.estimatedHeight(
                width: width,
                identification: identification,
                conversation: conversation)
        }
    }
}
