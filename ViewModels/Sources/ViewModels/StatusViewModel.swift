// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public struct StatusViewModel {
    public let content: NSAttributedString
    public let contentEmoji: [Emoji]
    public let displayName: String
    public let displayNameEmoji: [Emoji]
    public let spoilerText: String
    public let isReblog: Bool
    public let rebloggedByDisplayName: String
    public let rebloggedByDisplayNameEmoji: [Emoji]
    public let attachmentViewModels: [AttachmentViewModel]
    public let pollOptionTitles: [String]
    public let pollEmoji: [Emoji]
    public var isPinned = false
    public var isContextParent = false
    public var isReplyInContext = false
    public var hasReplyFollowing = false
    public var sensitiveContentToggled = false
    public let events: AnyPublisher<AnyPublisher<Never, Error>, Never>

    private let statusService: StatusService
    private let eventsInput = PassthroughSubject<AnyPublisher<Never, Error>, Never>()

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
        attachmentViewModels = statusService.status.displayStatus.mediaAttachments
            .map(AttachmentViewModel.init(attachment:))
        pollOptionTitles = statusService.status.displayStatus.poll?.options.map { $0.title } ?? []
        pollEmoji = statusService.status.displayStatus.poll?.emojis ?? []
        events = eventsInput.eraseToAnyPublisher()
    }
}

public extension StatusViewModel {
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

    var reblogged: Bool { statusService.status.displayStatus.reblogged }

    var favorited: Bool { statusService.status.displayStatus.favourited }

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

    func toggleFavorited() {
        eventsInput.send(statusService.toggleFavorited())
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
