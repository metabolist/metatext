// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct ProfileService {
    public let accountServicePublisher: AnyPublisher<AccountService, Error>

    private let accountID: String
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(account: Account, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.init(
            id: account.id,
            account: account,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
    }

    init(id: String, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.init(id: id, account: nil, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    private init(
        id: String,
        account: Account?,
        mastodonAPIClient: MastodonAPIClient,
        contentDatabase: ContentDatabase) {
        accountID = id
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase

        var accountPublisher = contentDatabase.accountObservation(id: accountID)
            .compactMap { $0 }
            .eraseToAnyPublisher()

        if let account = account {
            accountPublisher = accountPublisher
                .merge(with: Just(account).setFailureType(to: Error.self))
                .removeDuplicates()
                .eraseToAnyPublisher()
        }

        accountServicePublisher = accountPublisher
            .map { AccountService(account: $0, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase) }
            .eraseToAnyPublisher()
    }
}

public extension ProfileService {
    func statusListService(profileCollection: ProfileCollection) -> StatusListService {
        StatusListService(
            timeline: .profile(accountId: accountID, profileCollection: profileCollection),
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
    }

    func fetchPinnedStatuses() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(
            StatusesEndpoint.accountsStatuses(
                id: accountID,
                excludeReplies: true,
                onlyMedia: false,
                pinned: true))
            .flatMap { contentDatabase.insert(pinnedStatuses: $0, accountID: accountID) }
            .eraseToAnyPublisher()
    }
}
