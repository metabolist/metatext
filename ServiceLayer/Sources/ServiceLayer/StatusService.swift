// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import Mastodon

public struct StatusService {
    public let status: Status
    private let networkClient: APIClient
    private let contentDatabase: ContentDatabase

    init(status: Status, networkClient: APIClient, contentDatabase: ContentDatabase) {
        self.status = status
        self.networkClient = networkClient
        self.contentDatabase = contentDatabase
    }
}

public extension StatusService {
    func toggleFavorited() -> AnyPublisher<Never, Error> {
        networkClient.request(status.favourited
                                ? StatusEndpoint.unfavourite(id: status.id)
                                : StatusEndpoint.favourite(id: status.id))
            .map { ([$0], nil) }
            .flatMap(contentDatabase.insert(statuses:timeline:))
            .eraseToAnyPublisher()
    }
}
