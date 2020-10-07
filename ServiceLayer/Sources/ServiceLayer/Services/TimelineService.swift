// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct TimelineService {
    public let sections: AnyPublisher<[[CollectionItem]], Error>
    public let navigationService: NavigationService
    public let nextPageMaxId: AnyPublisher<String, Never>
    public let title: AnyPublisher<String, Never>

    private let timeline: Timeline
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let nextPageMaxIdSubject = PassthroughSubject<String, Never>()

    init(timeline: Timeline, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.timeline = timeline
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        sections = contentDatabase.timelinePublisher(timeline)
        navigationService = NavigationService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
        nextPageMaxId = nextPageMaxIdSubject.eraseToAnyPublisher()

        if case let .tag(tag) = timeline {
            title = Just("#".appending(tag)).eraseToAnyPublisher()
        } else {
            title = Empty().eraseToAnyPublisher()
        }
    }
}

extension TimelineService: CollectionService {
    public func request(maxId: String?, minId: String?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.pagedRequest(timeline.endpoint, maxId: maxId, minId: minId)
            .handleEvents(receiveOutput: {
                guard let maxId = $0.info.maxId else { return }

                nextPageMaxIdSubject.send(maxId)
            })
            .flatMap { contentDatabase.insert(statuses: $0.result, timeline: timeline) }
            .eraseToAnyPublisher()
    }

    public func toggleShowMore(id: Status.Id) -> AnyPublisher<Never, Error> {
        contentDatabase.toggleShowMore(id: id)
    }
}
