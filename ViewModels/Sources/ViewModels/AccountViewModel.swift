// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public class AccountViewModel: ObservableObject {
    public let events: AnyPublisher<AnyPublisher<CollectionItemEvent, Error>, Never>

    private let accountService: AccountService
    private let eventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()

    init(accountService: AccountService) {
        self.accountService = accountService
        events = eventsSubject.eraseToAnyPublisher()
    }
}

public extension AccountViewModel {
    var avatarURL: URL {
        accountService.account.avatar
    }

    var note: NSAttributedString {
        accountService.account.note.attributed
    }
}
