// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct StatusService {
    public let status: Status
    public let navigationService: NavigationService
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(status: Status, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.status = status
        self.navigationService = NavigationService(
            status: status.displayStatus,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
    }
}

public extension StatusService {
    func toggleFavorited() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(status.displayStatus.favourited
                                    ? StatusEndpoint.unfavourite(id: status.displayStatus.id)
                                    : StatusEndpoint.favourite(id: status.displayStatus.id))
            .flatMap(contentDatabase.insert(status:))
            .eraseToAnyPublisher()
    }

    func rebloggedByService() -> AccountListService {
        AccountListService(
            endpoint: .statusRebloggedBy(id: status.id),
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
    }

    func favoritedByService() -> AccountListService {
        AccountListService(
            endpoint: .statusFavouritedBy(id: status.id),
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
    }
}
