// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct TimelineService {
    public let sections: AnyPublisher<[[CollectionItem]], Error>
    public let navigationService: NavigationService
    public let nextPageMaxIDs: AnyPublisher<String?, Never>
    public let title: String?
    public let contextParentID: String? = nil

    private let timeline: Timeline
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let nextPageMaxIDsSubject = PassthroughSubject<String?, Never>()

    init(timeline: Timeline, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.timeline = timeline
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        sections = contentDatabase.observation(timeline: timeline)
        navigationService = NavigationService(
            status: nil,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
        nextPageMaxIDs = nextPageMaxIDsSubject.eraseToAnyPublisher()

        if case let .tag(tag) = timeline {
            title = "#".appending(tag)
        } else {
            title = nil
        }
    }
}

extension TimelineService: CollectionService {
    public func request(maxID: String?, minID: String?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.pagedRequest(timeline.endpoint, maxID: maxID, minID: minID)
            .handleEvents(receiveOutput: { nextPageMaxIDsSubject.send($0.info.maxID) })
            .flatMap { contentDatabase.insert(statuses: $0.result, timeline: timeline) }
            .eraseToAnyPublisher()
    }
}
