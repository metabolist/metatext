// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public struct StatusViewModel: CollectionItemViewModel {
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
    public var configuration = CollectionItem.StatusConfiguration.default
    public let events: AnyPublisher<AnyPublisher<CollectionItemEvent, Error>, Never>

    private let statusService: StatusService
    private let eventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()
    private let identification: Identification

    init(statusService: StatusService, identification: Identification) {
        self.statusService = statusService
        self.identification = identification
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
        events = eventsSubject.eraseToAnyPublisher()
    }
}

public extension StatusViewModel {
    var shouldShowMore: Bool {
        guard statusService.status.spoilerText != "" else { return true }

        if identification.identity.preferences.readingExpandSpoilers {
            return !configuration.showMoreToggled
        } else {
            return configuration.showMoreToggled
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

    var cardViewModel: CardViewModel? {
        if let card = statusService.status.displayStatus.card {
            return CardViewModel(card: card)
        } else {
            return nil
        }
    }

    var canBeReblogged: Bool {
        switch statusService.status.displayStatus.visibility {
        case .direct, .private:
            return false
        default:
            return true
        }
    }

    func toggleShowMore() {
        eventsSubject.send(
            statusService.toggleShowMore()
                .map { _ in CollectionItemEvent.ignorableOutput }
                .eraseToAnyPublisher())
    }

    func urlSelected(_ url: URL) {
        eventsSubject.send(
            statusService.navigationService.item(url: url)
                .map { CollectionItemEvent.navigation($0) }
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func accountSelected() {
        eventsSubject.send(
            Just(CollectionItemEvent.navigation(
                    .profile(
                        statusService.navigationService.profileService(
                            account: statusService.status.displayStatus.account))))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func rebloggedBySelected() {
        eventsSubject.send(
            Just(CollectionItemEvent.navigation(.collection(statusService.rebloggedByService())))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func favoritedBySelected() {
        eventsSubject.send(
            Just(CollectionItemEvent.navigation(.collection(statusService.favoritedByService())))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func toggleFavorited() {
        eventsSubject.send(
            statusService.toggleFavorited()
                .map { _ in CollectionItemEvent.ignorableOutput }
                .eraseToAnyPublisher())
    }

    func shareStatus() {
        guard let url = statusService.status.displayStatus.url else { return }

        eventsSubject.send(Just(CollectionItemEvent.share(url)).setFailureType(to: Error.self).eraseToAnyPublisher())
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
