// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import MastodonAPI

public struct LoadMoreService {
    private let loadMore: LoadMore
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(loadMore: LoadMore, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.loadMore = loadMore
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
    }
}

public extension LoadMoreService {
    func request(direction: LoadMore.Direction) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.pagedRequest(
            loadMore.timeline.endpoint,
            maxId: direction == .down ? loadMore.afterStatusId : nil,
            minId: direction == .up ? loadMore.beforeStatusId : nil)
            .flatMap {
                contentDatabase.insert(
                    statuses: $0.result,
                    timeline: loadMore.timeline,
                    loadMoreAndDirection: (loadMore, direction))
            }
            .eraseToAnyPublisher()
    }
}
