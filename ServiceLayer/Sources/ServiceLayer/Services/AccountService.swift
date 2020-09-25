// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct AccountService {
    public let account: Account
    public let navigationService: NavigationService
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(account: Account, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.account = account
        self.navigationService = NavigationService(
            status: nil,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
    }
}
