// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

struct TimelineService: StatusListService {
    let statusSections: AnyPublisher<[[Status]], Error>

    private let timeline: Timeline
    private let networkClient: MastodonClient
    private let contentDatabase: ContentDatabase

    init(timeline: Timeline, networkClient: MastodonClient, contentDatabase: ContentDatabase) {
        self.timeline = timeline
        self.networkClient = networkClient
        self.contentDatabase = contentDatabase
        statusSections = contentDatabase.statusesObservation(timeline: timeline)
            .map { [$0] }
            .eraseToAnyPublisher()
    }

    func request(maxID: String?, minID: String?) -> AnyPublisher<Void, Error> {
        return networkClient.request(timeline.endpoint)
            .map { ($0, timeline) }
            .flatMap(contentDatabase.insert(statuses:collection:))
            .eraseToAnyPublisher()
    }
}
