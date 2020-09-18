// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct AccountStatusesService {
    private let accountID: String
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(id: String, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        accountID = id
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
    }
}

public extension AccountStatusesService {
    func statusListService(collectionPublisher: AnyPublisher<AccountStatusCollection, Never>) -> StatusListService {
        StatusListService(
            accountID: accountID,
            collection: collectionPublisher,
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
