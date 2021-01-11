// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class StatusViewModel: CollectionItemViewModel, AttachmentsRenderingViewModel, ObservableObject {
    public let content: NSAttributedString
    public let contentEmoji: [Emoji]
    public let displayName: String
    public let displayNameEmoji: [Emoji]
    public let spoilerText: String
    public let isReblog: Bool
    public let rebloggedByDisplayName: String
    public let rebloggedByDisplayNameEmoji: [Emoji]
    public let attachmentViewModels: [AttachmentViewModel]
    public let pollEmoji: [Emoji]
    @Published public var pollOptionSelections = Set<Int>()
    public var configuration = CollectionItem.StatusConfiguration.default
    public let events: AnyPublisher<AnyPublisher<CollectionItemEvent, Error>, Never>

    private let statusService: StatusService
    private let identification: Identification
    private let eventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()

    init(statusService: StatusService, identification: Identification) {
        self.statusService = statusService
        self.identification = identification
        content = statusService.status.displayStatus.content.attributed
        contentEmoji = statusService.status.displayStatus.emojis
        displayName = statusService.status.displayStatus.account.displayName.isEmpty
            ? statusService.status.displayStatus.account.username
            : statusService.status.displayStatus.account.displayName
        displayNameEmoji = statusService.status.displayStatus.account.emojis
        spoilerText = statusService.status.displayStatus.spoilerText
        isReblog = statusService.status.reblog != nil
        rebloggedByDisplayName = statusService.status.account.displayName.isEmpty
            ? statusService.status.account.username
            : statusService.status.account.displayName
        rebloggedByDisplayNameEmoji = statusService.status.account.emojis
        attachmentViewModels = statusService.status.displayStatus.mediaAttachments
            .map { AttachmentViewModel(attachment: $0, identification: identification, status: statusService.status) }
        pollEmoji = statusService.status.displayStatus.poll?.emojis ?? []
        events = eventsSubject.eraseToAnyPublisher()
    }
}

public extension StatusViewModel {
    var isMine: Bool { statusService.status.displayStatus.account.id == identification.identity.account?.id }

    var shouldShowContent: Bool {
        guard spoilerText != "" else { return true }

        if identification.identity.preferences.readingExpandSpoilers {
            return !configuration.showContentToggled
        } else {
            return configuration.showContentToggled
        }
    }

    var shouldShowAttachments: Bool {
        switch identification.identity.preferences.readingExpandMedia {
        case .default, .unknown:
            return !sensitive || configuration.showAttachmentsToggled
        case .showAll:
            return !configuration.showAttachmentsToggled
        case .hideAll:
            return configuration.showAttachmentsToggled
        }
    }

    var shouldShowHideAttachmentsButton: Bool {
        sensitive || identification.identity.preferences.readingExpandMedia == .hideAll
    }

    var id: Status.Id { statusService.status.displayStatus.id }

    var accountName: String { "@".appending(statusService.status.displayStatus.account.acct) }

    var avatarURL: URL {
        if !identification.appPreferences.shouldReduceMotion,
           identification.appPreferences.animateAvatars == .everywhere {
            return statusService.status.displayStatus.account.avatar
        } else {
            return statusService.status.displayStatus.account.avatarStatic
        }
    }

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

    var bookmarked: Bool { statusService.status.displayStatus.bookmarked }

    var sensitive: Bool { statusService.status.displayStatus.sensitive }

    var pinned: Bool? { statusService.status.displayStatus.pinned }

    var muted: Bool { statusService.status.displayStatus.muted }

    var sharingURL: URL? { statusService.status.displayStatus.url }

    var isPollExpired: Bool { statusService.status.displayStatus.poll?.expired ?? true }

    var hasVotedInPoll: Bool { statusService.status.displayStatus.poll?.voted ?? false }

    var isPollMultipleSelection: Bool { statusService.status.displayStatus.poll?.multiple ?? false }

    var pollOptions: [Poll.Option] { statusService.status.displayStatus.poll?.options ?? [] }

    var pollVotersCount: Int {
        guard let poll = statusService.status.displayStatus.poll else { return 0 }

        return poll.votersCount ?? poll.votesCount
    }

    var pollOwnVotes: Set<Int> { Set(statusService.status.displayStatus.poll?.ownVotes ?? []) }

    var pollTimeLeft: String? {
        guard let expiresAt = statusService.status.displayStatus.poll?.expiresAt,
              expiresAt > Date()
        else { return nil }

        return expiresAt.fullUnitTimeUntil
    }

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

    func toggleShowContent() {
        eventsSubject.send(
            statusService.toggleShowContent()
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func toggleShowAttachments() {
        eventsSubject.send(
            statusService.toggleShowAttachments()
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func urlSelected(_ url: URL) {
        eventsSubject.send(
            statusService.navigationService.item(url: url)
                .map { .navigation($0) }
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func accountSelected() {
        eventsSubject.send(
            Just(.navigation(
                    .profile(
                        statusService.navigationService.profileService(
                            account: statusService.status.displayStatus.account))))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func rebloggedBySelected() {
        eventsSubject.send(
            Just(.navigation(.collection(statusService.rebloggedByService())))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func favoritedBySelected() {
        eventsSubject.send(
            Just(.navigation(.collection(statusService.favoritedByService())))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func reply() {
        let replyViewModel = Self(statusService: statusService, identification: identification)

        replyViewModel.configuration = configuration.reply()

        eventsSubject.send(
            Just(.compose(inReplyTo: replyViewModel, redraft: nil))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func toggleReblogged() {
        eventsSubject.send(
            statusService.toggleReblogged()
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func toggleFavorited() {
        eventsSubject.send(
            statusService.toggleFavorited()
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func toggleBookmarked() {
        eventsSubject.send(
            statusService.toggleBookmarked()
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func togglePinned() {
        eventsSubject.send(
            statusService.togglePinned()
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func toggleMuted() {
        eventsSubject.send(
            statusService.toggleMuted()
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func confirmDelete(redraft: Bool) {
        eventsSubject.send(
            Just(.confirmDelete(self, redraft: redraft))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func delete() {
        eventsSubject.send(
            statusService.delete()
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func deleteAndRedraft() {
        let identification = self.identification

        eventsSubject.send(
            statusService.deleteAndRedraft()
                .map { redraft, inReplyToStatusService in
                    let inReplyToViewModel: StatusViewModel?

                    if let inReplyToStatusService = inReplyToStatusService {
                        inReplyToViewModel = Self(
                            statusService: inReplyToStatusService,
                            identification: identification)
                        inReplyToViewModel?.configuration = CollectionItem.StatusConfiguration.default.reply()
                    } else {
                        inReplyToViewModel = nil
                    }

                    return .compose(inReplyTo: inReplyToViewModel, redraft: redraft)
                }
                .eraseToAnyPublisher())
    }

    func attachmentSelected(viewModel: AttachmentViewModel) {
        eventsSubject.send(Just(.attachment(viewModel, self)).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    func shareStatus() {
        guard let url = statusService.status.displayStatus.url else { return }

        eventsSubject.send(Just(.share(url)).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    func reportStatus() {
        eventsSubject.send(
            Just(.report(ReportViewModel(
                            accountService: statusService.navigationService.accountService(
                                account: statusService.status.displayStatus.account),
                            statusService: statusService,
                            identification: identification)))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func vote() {
        eventsSubject.send(
            statusService.vote(selectedOptions: pollOptionSelections)
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func refreshPoll() {
        eventsSubject.send(
            statusService.refreshPoll()
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
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
