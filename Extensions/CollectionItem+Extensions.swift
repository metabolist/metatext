// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
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
        SeparatorConfiguredTableViewCell.self]

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
            return SeparatorConfiguredTableViewCell.self
        }
    }

    func estimatedHeight(width: CGFloat, identityContext: IdentityContext) -> CGFloat {
        switch self {
        case let .status(status, configuration, _):
            return StatusView.estimatedHeight(
                width: width,
                identityContext: identityContext,
                status: status,
                configuration: configuration)
        case let .account(account, configuration, _):
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

    func mediaPrefetchURLs(identityContext: IdentityContext) -> Set<URL> {
        switch self {
        case let .status(status, _, _):
            return status.mediaPrefetchURLs(identityContext: identityContext)
        case let .account(account, _, _):
            return account.mediaPrefetchURLs(identityContext: identityContext)
        case let .notification(notification, _):
            var urls = notification.account.mediaPrefetchURLs(identityContext: identityContext)

            if let status = notification.status {
                urls.formUnion(status.mediaPrefetchURLs(identityContext: identityContext))
            }

            return urls
        case let .conversation(conversation):
            return conversation.accounts.reduce(Set<URL>()) {
                $0.union($1.mediaPrefetchURLs(identityContext: identityContext))
            }
        default:
            return []
        }
    }
}

private extension Account {
    func mediaPrefetchURLs(identityContext: IdentityContext) -> Set<URL> {
        var urls = Set(emojis.compactMap {
            identityContext.appPreferences.animateCustomEmojis ? $0.url : $0.staticUrl
        }
        .compactMap(URL.init(string:)))

        if !identityContext.appPreferences.shouldReduceMotion
            && identityContext.appPreferences.animateAvatars == .everywhere {
            urls.insert(avatar)
        } else {
            urls.insert(avatarStatic)
        }

        return urls
    }
}

private extension Status {
    func mediaPrefetchURLs(identityContext: IdentityContext) -> Set<URL> {
        displayStatus.account.mediaPrefetchURLs(identityContext: identityContext)
            .union(displayStatus.mediaAttachments.compactMap(\.previewUrl))
            .union(displayStatus.emojis.compactMap {
                identityContext.appPreferences.animateCustomEmojis ? $0.url : $0.staticUrl
            }
            .compactMap(URL.init(string:)))
    }
}
