// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public class AccountViewModel: ObservableObject {
    private let accountService: AccountService

    init(accountService: AccountService) {
        self.accountService = accountService
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
