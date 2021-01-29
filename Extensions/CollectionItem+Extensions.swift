// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

extension CollectionItem {
    static let cellClasses = [
        StatusTableViewCell.self,
        AccountTableViewCell.self,
        LoadMoreTableViewCell.self,
        NotificationTableViewCell.self,
        ConversationTableViewCell.self,
        TagTableViewCell.self,
        UITableViewCell.self]

    var cellClass: AnyClass {
        switch self {
        case .status:
            return StatusTableViewCell.self
        case .account:
            return AccountTableViewCell.self
        case .loadMore:
            return LoadMoreTableViewCell.self
        case let .notification(_, statusConfiguration):
            return statusConfiguration == nil ? NotificationTableViewCell.self : StatusTableViewCell.self
        case .conversation:
            return ConversationTableViewCell.self
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
        case let .account(account, configuration):
            return AccountView.estimatedHeight(width: width, account: account, configuration: configuration)
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
