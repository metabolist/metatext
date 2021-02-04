// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class AccountViewModel: CollectionItemViewModel, ObservableObject {
    public let events: AnyPublisher<AnyPublisher<CollectionItemEvent, Error>, Never>
    public let identityContext: IdentityContext
    public internal(set) var configuration = CollectionItem.AccountConfiguration.withNote

    private let accountService: AccountService
    private let eventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()

    init(accountService: AccountService, identityContext: IdentityContext) {
        self.accountService = accountService
        self.identityContext = identityContext
        events = eventsSubject.eraseToAnyPublisher()
    }
}

public extension AccountViewModel {
    var id: Account.Id { accountService.account.id }

    var headerURL: URL {
        if !identityContext.appPreferences.shouldReduceMotion, identityContext.appPreferences.animateHeaders {
            return accountService.account.header
        } else {
            return accountService.account.headerStatic
        }
    }

    var isLocal: Bool { accountService.isLocal }

    var domain: String? { accountService.domain }

    var displayName: String {
        accountService.account.displayName.isEmpty ? accountService.account.acct : accountService.account.displayName
    }

    var accountName: String { "@".appending(accountService.account.acct) }

    var isLocked: Bool { accountService.account.locked }

    var relationship: Relationship? { accountService.relationship }

    var identityProofs: [IdentityProof] { accountService.identityProofs }

    var featuredTags: [FeaturedTag] { accountService.featuredTags }

    var fields: [Account.Field] { accountService.account.fields }

    var note: NSAttributedString { accountService.account.note.attributed }

    var emojis: [Emoji] { accountService.account.emojis }

    var followingCount: Int { accountService.account.followingCount }

    var followersCount: Int { accountService.account.followersCount }

    var isSelf: Bool { accountService.account.id == identityContext.identity.account?.id }

    func avatarURL(profile: Bool = false) -> URL {
        if !identityContext.appPreferences.shouldReduceMotion,
           (identityContext.appPreferences.animateAvatars == .everywhere
                || (identityContext.appPreferences.animateAvatars == .profiles && profile)) {
            return accountService.account.avatar
        } else {
            return accountService.account.avatarStatic
        }
    }

    func urlSelected(_ url: URL) {
        eventsSubject.send(
            accountService.navigationService.item(url: url)
                .map { CollectionItemEvent.navigation($0) }
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func followingSelected() {
        eventsSubject.send(
            Just(.navigation(.collection(accountService.followingService())))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func followersSelected() {
        eventsSubject.send(
            Just(.navigation(.collection(accountService.followersService())))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func reportViewModel() -> ReportViewModel {
        ReportViewModel(accountService: accountService, identityContext: identityContext)
    }

    func follow() {
        ignorableOutputEvent(accountService.follow())
    }

    func unfollow() {
        ignorableOutputEvent(accountService.unfollow())
    }

    func hideReblogs() {
        ignorableOutputEvent(accountService.hideReblogs())
    }

    func showReblogs() {
        ignorableOutputEvent(accountService.showReblogs())
    }

    func block() {
        ignorableOutputEvent(accountService.block())
    }

    func unblock() {
        ignorableOutputEvent(accountService.unblock())
    }

    func mute() {
        ignorableOutputEvent(accountService.mute())
    }

    func unmute() {
        ignorableOutputEvent(accountService.unmute())
    }

    func pin() {
        ignorableOutputEvent(accountService.pin())
    }

    func unpin() {
        ignorableOutputEvent(accountService.unpin())
    }

    func set(note: String) {
        ignorableOutputEvent(accountService.set(note: note))
    }

    func acceptFollowRequest() {
        accountListEdit(accountService.acceptFollowRequest(), event: .acceptFollowRequest)
    }

    func rejectFollowRequest() {
        accountListEdit(accountService.rejectFollowRequest(), event: .rejectFollowRequest)
    }

    func domainBlock() {
        ignorableOutputEvent(accountService.domainBlock())
    }

    func domainUnblock() {
        ignorableOutputEvent(accountService.domainUnblock())
    }
}

private extension AccountViewModel {
    func ignorableOutputEvent(_ action: AnyPublisher<Never, Error>) {
        eventsSubject.send(action.map { _ in .ignorableOutput }.eraseToAnyPublisher())
    }

    func accountListEdit(_ action: AnyPublisher<Never, Error>, event: CollectionItemEvent.AccountListEdit) {
        eventsSubject.send(
            action.collect()
                .map { [weak self] _ -> CollectionItemEvent in
                    guard let self = self else { return .ignorableOutput }

                    return .accountListEdit(self, .acceptFollowRequest)
                }
                .eraseToAnyPublisher())
    }
}
