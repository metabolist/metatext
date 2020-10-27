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
    private let nextPageMaxIdSubject: CurrentValueSubject<String, Never>

    init(timeline: Timeline, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.timeline = timeline
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase

        let nextPageMaxIdSubject = CurrentValueSubject<String, Never>(String(Int.max))

        self.nextPageMaxIdSubject = nextPageMaxIdSubject
        sections = contentDatabase.timelinePublisher(timeline)
            .handleEvents(receiveOutput: {
                guard case let .status(status, _) = $0.last?.last,
                      status.id < nextPageMaxIdSubject.value
                else { return }

                nextPageMaxIdSubject.send(status.id)
            })
            .eraseToAnyPublisher()
        navigationService = NavigationService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
        nextPageMaxId = nextPageMaxIdSubject.dropFirst().eraseToAnyPublisher()

        if case let .tag(tag) = timeline {
            title = Just("#".appending(tag)).eraseToAnyPublisher()
        } else {
            title = Empty().eraseToAnyPublisher()
        }
    }
}

extension TimelineService: CollectionService {
    public var markerTimeline: Marker.Timeline? {
        switch timeline {
        case .home:
            return .home
        default:
            return nil
        }
    }

    public func request(maxId: String?, minId: String?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.pagedRequest(timeline.endpoint, maxId: maxId, minId: minId)
            .handleEvents(receiveOutput: {
                guard let maxId = $0.info.maxId, maxId < nextPageMaxIdSubject.value else { return }

                nextPageMaxIdSubject.send(maxId)
            })
            .flatMap { contentDatabase.insert(statuses: $0.result, timeline: timeline) }
            .eraseToAnyPublisher()
    }
}
