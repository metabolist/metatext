// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public struct AccountViewModel: CollectionItemViewModel {
    public let events: AnyPublisher<AnyPublisher<CollectionItemEvent, Error>, Never>

    private let accountService: AccountService
    private let identification: Identification
    private let eventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()

    init(accountService: AccountService, identification: Identification) {
        self.accountService = accountService
        self.identification = identification
        events = eventsSubject.eraseToAnyPublisher()
    }
}

public extension AccountViewModel {
    var headerURL: URL {
        if !identification.appPreferences.shouldReduceMotion, identification.appPreferences.animateHeaders {
            return accountService.account.header
        } else {
            return accountService.account.headerStatic
        }
    }

    var displayName: String {
        accountService.account.displayName.isEmpty ? accountService.account.acct : accountService.account.displayName
    }

    var accountName: String { "@".appending(accountService.account.acct) }

    var isLocked: Bool { accountService.account.locked }

    var fields: [Account.Field] { accountService.account.fields }

    var note: NSAttributedString { accountService.account.note.attributed }

    var emoji: [Emoji] { accountService.account.emojis }

    var isSelf: Bool { accountService.account.id == identification.identity.account?.id }

    func avatarURL(profile: Bool = false) -> URL {
        if !identification.appPreferences.shouldReduceMotion,
           (identification.appPreferences.animateAvatars == .everywhere
                || identification.appPreferences.animateAvatars == .profiles && profile) {
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
}
