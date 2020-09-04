// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import DB
import Mastodon
import MastodonAPI

public struct StatusService {
    public let status: Status
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(status: Status, networkClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.status = status
        self.mastodonAPIClient = networkClient
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
}
