// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

extension CollectionItem {
    static let cellClasses = [
        StatusListCell.self,
        AccountListCell.self,
        LoadMoreCell.self,
        NotificationListCell.self,
        ConversationListCell.self,
        TagTableViewCell.self,
        UITableViewCell.self]

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
        case .tag:
            return TagTableViewCell.self
        case .moreResults:
            return UITableViewCell.self
        }
    }

    func estimatedHeight(width: CGFloat, identityContext: IdentityContext) -> CGFloat {
        switch self {
        case let .status(status, configuration):
            return StatusView.estimatedHeight(
                width: width,
                identityContext: identityContext,
                status: status,
                configuration: configuration)
        case let .account(account):
            return AccountView.estimatedHeight(width: width, account: account)
        case .loadMore:
            return LoadMoreView.estimatedHeight
        case let .notification(notification, configuration):
            return NotificationView.estimatedHeight(
                width: width,
                identityContext: identityContext,
                notification: notification,
                configuration: configuration)
        case let .conversation(conversation):
            return ConversationView.estimatedHeight(
                width: width,
                identityContext: identityContext,
                conversation: conversation)
        case let .tag(tag):
            return TagView.estimatedHeight(width: width, tag: tag)
        case .moreResults:
            return UITableView.automaticDimension
        }
    }
}
