// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct TimelineService {
    public let sections: AnyPublisher<[[CollectionItem]], Error>
    public let navigationService: NavigationService
    public let nextPageMaxIDs: AnyPublisher<String, Never>
    public let title: AnyPublisher<String, Never>
    public let contextParentID: String? = nil

    private let timeline: Timeline
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let nextPageMaxIDsSubject = PassthroughSubject<String, Never>()

    init(timeline: Timeline, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.timeline = timeline
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        sections = contentDatabase.observation(timeline: timeline)
        navigationService = NavigationService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
        nextPageMaxIDs = nextPageMaxIDsSubject.eraseToAnyPublisher()

        if case let .tag(tag) = timeline {
            title = Just("#".appending(tag)).eraseToAnyPublisher()
        } else {
            title = Empty().eraseToAnyPublisher()
        }
    }
}

extension TimelineService: CollectionService {
    public func request(maxID: String?, minID: String?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.pagedRequest(timeline.endpoint, maxID: maxID, minID: minID)
            .handleEvents(receiveOutput: {
                guard let maxID = $0.info.maxID else { return }

                nextPageMaxIDsSubject.send(maxID)
            })
            .flatMap { contentDatabase.insert(statuses: $0.result, timeline: timeline) }
            .eraseToAnyPublisher()
    }
}
