// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public struct AccountViewModel: CollectionItemViewModel {
    public let events: AnyPublisher<AnyPublisher<CollectionItemEvent, Error>, Never>
    public let identification: Identification

    private let accountService: AccountService
    private let eventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()

    init(accountService: AccountService, identification: Identification) {
        self.accountService = accountService
        self.identification = identification
        events = eventsSubject.eraseToAnyPublisher()
    }
}

public extension AccountViewModel {
    var avatarURL: URL { accountService.account.avatar }

    var avatarStaticURL: URL { accountService.account.avatarStatic }

    var headerURL: URL { accountService.account.header }

    var headerStaticURL: URL { accountService.account.headerStatic }

    var displayName: String { accountService.account.displayName }

    var accountName: String { "@".appending(accountService.account.acct) }

    var note: NSAttributedString { accountService.account.note.attributed }

    var emoji: [Emoji] { accountService.account.emojis }

    func urlSelected(_ url: URL) {
        eventsSubject.send(
            accountService.navigationService.item(url: url)
                .map { CollectionItemEvent.navigation($0) }
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }
}
