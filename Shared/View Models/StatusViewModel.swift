// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

struct StatusViewModel {
    let content: NSAttributedString
    let contentEmoji: [Emoji]
    let displayName: String
    let displayNameEmoji: [Emoji]
    let spoilerText: String
    let isReblog: Bool
    let rebloggedByDisplayName: String
    let rebloggedByDisplayNameEmoji: [Emoji]
    let pollOptionTitles: [String]
    let pollEmoji: [Emoji]
    var isPinned = false
    var isContextParent = false
    var isReplyInContext = false
    var hasReplyFollowing = false
    var sensitiveContentToggled = false

    private let statusService: StatusService

    init(statusService: StatusService) {
        self.statusService = statusService
        content = statusService.status.displayStatus.content.attributed
        contentEmoji = statusService.status.displayStatus.emojis
        displayName = statusService.status.displayStatus.account.displayName == ""
            ? statusService.status.displayStatus.account.username
            : statusService.status.displayStatus.account.displayName
        displayNameEmoji = statusService.status.displayStatus.account.emojis
        spoilerText = statusService.status.displayStatus.spoilerText
        isReblog = statusService.status.reblog != nil
        rebloggedByDisplayName = statusService.status.account.displayName == ""
            ? statusService.status.account.username
            : statusService.status.account.displayName
        rebloggedByDisplayNameEmoji = statusService.status.account.emojis
        pollOptionTitles = statusService.status.displayStatus.poll?.options.map { $0.title } ?? []
        pollEmoji = statusService.status.displayStatus.poll?.emojis ?? []
    }
}

extension StatusViewModel {
    var shouldDisplaySensitiveContent: Bool {
        if statusService.status.displayStatus.sensitive {
            return sensitiveContentToggled
        } else {
            return true
        }
    }

    var accountName: String { "@" + statusService.status.displayStatus.account.acct }

    var avatarURL: URL { statusService.status.displayStatus.account.avatar }

    var time: String? { statusService.status.displayStatus.createdAt.timeAgo }

    var contextParentTime: String {
        Self.contextParentDateFormatter.string(from: statusService.status.displayStatus.createdAt)
    }

    var applicationName: String? { statusService.status.displayStatus.application?.name }

    var applicationURL: URL? {
        guard let website = statusService.status.displayStatus.application?.website else { return nil }

        return URL(string: website)
    }

    var repliesCount: Int { statusService.status.displayStatus.repliesCount }

    var reblogsCount: Int { statusService.status.displayStatus.reblogsCount }

    var favoritesCount: Int { statusService.status.displayStatus.favouritesCount }

    var reblogged: Bool { statusService.status.displayStatus.reblogged ?? false }

    var favorited: Bool { statusService.status.displayStatus.favourited ?? false }

    var sensitive: Bool { statusService.status.displayStatus.sensitive }

    var sharingURL: URL? { statusService.status.displayStatus.url }

    var cardURL: URL? { statusService.status.displayStatus.card?.url }

    var cardTitle: String? { statusService.status.displayStatus.card?.title }

    var cardDescription: String? { statusService.status.displayStatus.card?.description }

    var cardImageURL: URL? { statusService.status.displayStatus.card?.image }

    var canBeReblogged: Bool {
        switch statusService.status.displayStatus.visibility {
        case .direct, .private:
            return false
        default:
            return true
        }
    }
}

private extension StatusViewModel {
    private static let contextParentDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        return dateFormatter
    }()
}
