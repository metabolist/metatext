// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class StatusViewModel: AttachmentsRenderingViewModel, ObservableObject {
    public let accountViewModel: AccountViewModel
    public let content: NSAttributedString
    public let contentEmojis: [Emoji]
    public let spoilerText: String
    public let isReblog: Bool
    public let rebloggedByDisplayName: String
    public let rebloggedByDisplayNameEmojis: [Emoji]
    public let attachmentViewModels: [AttachmentViewModel]
    public let pollEmojis: [Emoji]
    @Published public var pollOptionSelections = Set<Int>()
    public var configuration = CollectionItem.StatusConfiguration.default
    public var showReportSelectionToggle = false
    public var selectedForReport = false
    public let identityContext: IdentityContext

    private let statusService: StatusService
    private let eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>

    init(statusService: StatusService,
         identityContext: IdentityContext,
         eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>) {
        self.statusService = statusService
        self.identityContext = identityContext
        self.eventsSubject = eventsSubject
        accountViewModel = AccountViewModel(
            accountService: statusService.navigationService
                .accountService(account: statusService.status.displayStatus.account),
            identityContext: identityContext,
            eventsSubject: eventsSubject)
        content = statusService.status.displayStatus.content.attributed
        contentEmojis = statusService.status.displayStatus.emojis
        spoilerText = statusService.status.displayStatus.spoilerText
        isReblog = statusService.status.reblog != nil
        rebloggedByDisplayName = statusService.status.account.displayName.isEmpty
            ? statusService.status.account.username
            : statusService.status.account.displayName
        rebloggedByDisplayNameEmojis = statusService.status.account.emojis
        attachmentViewModels = statusService.status.displayStatus.mediaAttachments
            .map { AttachmentViewModel(attachment: $0, identityContext: identityContext, status: statusService.status) }
        pollEmojis = statusService.status.displayStatus.poll?.emojis ?? []
    }
}

public extension StatusViewModel {
    var isMine: Bool { statusService.status.displayStatus.account.id == identityContext.identity.account?.id }

    var shouldShowContent: Bool {
        guard spoilerText != "" else { return true }

        if identityContext.identity.preferences.readingExpandSpoilers {
            return !configuration.showContentToggled
        } else {
            return configuration.showContentToggled
        }
    }

    var shouldShowAttachments: Bool {
        switch identityContext.identity.preferences.readingExpandMedia {
        case .default, .unknown:
            return !sensitive || configuration.showAttachmentsToggled
        case .showAll:
            return !configuration.showAttachmentsToggled
        case .hideAll:
            return configuration.showAttachmentsToggled
        }
    }

    var shouldShowHideAttachmentsButton: Bool {
        sensitive || identityContext.identity.preferences.readingExpandMedia == .hideAll
    }

    var id: Status.Id { statusService.status.displayStatus.id }

    var accountName: String { "@".appending(statusService.status.displayStatus.account.acct) }

    var avatarURL: URL {
        if identityContext.appPreferences.animateAvatars == .everywhere {
            return statusService.status.displayStatus.account.avatar
        } else {
            return statusService.status.displayStatus.account.avatarStatic
        }
    }

    var rebloggerAvatarURL: URL {
        if identityContext.appPreferences.animateAvatars == .everywhere {
            return statusService.status.account.avatar
        } else {
            return statusService.status.account.avatarStatic
        }
    }

    var time: String? { statusService.status.displayStatus.createdAt.timeAgo }

    var accessibilityTime: String? { statusService.status.displayStatus.createdAt.accessibilityTimeAgo }

    var contextParentTime: String {
        Self.contextParentDateFormatter.string(from: statusService.status.displayStatus.createdAt)
    }

    var accessibilityContextParentTime: String {
        Self.contextParentAccessibilityDateFormatter.string(from: statusService.status.displayStatus.createdAt)
    }

    var applicationName: String? { statusService.status.displayStatus.application?.name }

    var applicationURL: URL? {
        guard let website = statusService.status.displayStatus.application?.website else { return nil }

        return URL(string: website)
    }

    var mentions: [Mention] { statusService.status.displayStatus.mentions }

    var visibility: Status.Visibility { statusService.status.displayStatus.visibility }

    var repliesCount: Int { statusService.status.displayStatus.repliesCount }

    var reblogsCount: Int { statusService.status.displayStatus.reblogsCount }

    var favoritesCount: Int { statusService.status.displayStatus.favouritesCount }

    var reblogged: Bool { statusService.status.displayStatus.reblogged }

    var favorited: Bool { statusService.status.displayStatus.favourited }

    var bookmarked: Bool { statusService.status.displayStatus.bookmarked }

    var sensitive: Bool { statusService.status.displayStatus.sensitive }

    var pinned: Bool? { statusService.status.displayStatus.pinned }

    var muted: Bool { statusService.status.displayStatus.muted }

    var sharingURL: URL? {
        guard let urlString = statusService.status.displayStatus.url else { return nil }

        return URL(string: urlString)
    }

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

    func rebloggerAccountSelected() {
        eventsSubject.send(
            Just(.navigation(
                    .profile(
                        statusService.navigationService.profileService(
                            account: statusService.status.account))))
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

    func reply(identity: Identity? = nil) {
        if let identity = identity {
            let identityContext = self.identityContext
            let configuration = self.configuration.reply()

            eventsSubject.send(statusService.asIdentity(id: identity.id).map {
                let replyViewModel = Self(statusService: $0,
                                          identityContext: identityContext,
                                          eventsSubject: .init())

                replyViewModel.configuration = configuration

                return CollectionItemEvent.compose(identity: identity, inReplyTo: replyViewModel)
            }
            .eraseToAnyPublisher())
        } else {
            let replyViewModel = Self(statusService: statusService,
                                      identityContext: identityContext,
                                      eventsSubject: .init())

            replyViewModel.configuration = configuration.reply()

            eventsSubject.send(
                Just(.compose(inReplyTo: replyViewModel))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher())
        }
    }

    func toggleReblogged(identityId: Identity.Id? = nil) {
        eventsSubject.send(
            statusService.toggleReblogged(identityId: identityId)
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func toggleFavorited(identityId: Identity.Id? = nil) {
        eventsSubject.send(
            statusService.toggleFavorited(identityId: identityId)
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
                .collect()
                .map { _ in .refresh }
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
        let isContextParent = configuration.isContextParent

        eventsSubject.send(
            statusService.delete()
                .map { _ in isContextParent ? .contextParentDeleted : .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func deleteAndRedraft() {
        let identityContext = self.identityContext
        let isContextParent = configuration.isContextParent

        eventsSubject.send(
            statusService.deleteAndRedraft()
                .map { redraft, inReplyToStatusService in
                    let inReplyToViewModel: StatusViewModel?

                    if let inReplyToStatusService = inReplyToStatusService {
                        inReplyToViewModel = Self(
                            statusService: inReplyToStatusService,
                            identityContext: identityContext,
                            eventsSubject: .init())
                        inReplyToViewModel?.configuration = CollectionItem.StatusConfiguration.default.reply()
                    } else {
                        inReplyToViewModel = nil
                    }

                    return .compose(inReplyTo: inReplyToViewModel,
                                    redraft: redraft,
                                    redraftWasContextParent: isContextParent)
                }
                .eraseToAnyPublisher())
    }

    func attachmentSelected(viewModel: AttachmentViewModel) {
        if viewModel.attachment.type == .unknown, let remoteUrl = viewModel.attachment.remoteUrl {
            urlSelected(remoteUrl)
        } else {
            eventsSubject.send(Just(.attachment(viewModel, self)).setFailureType(to: Error.self).eraseToAnyPublisher())
        }
    }

    func shareStatus() {
        guard let urlString = statusService.status.displayStatus.url,
              let url = URL(string: urlString)
              else { return }

        eventsSubject.send(Just(.share(url)).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    func reportStatus() {
        eventsSubject.send(
            Just(.report(ReportViewModel(
                            accountService: statusService.navigationService.accountService(
                                account: statusService.status.displayStatus.account),
                            statusId: statusService.status.displayStatus.id,
                            identityContext: identityContext)))
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

    private static let contextParentAccessibilityDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short

        return dateFormatter
    }()
}
