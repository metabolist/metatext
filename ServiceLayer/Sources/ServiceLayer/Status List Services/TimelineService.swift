// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import Mastodon

struct TimelineService {
    let statusSections: AnyPublisher<[[Status]], Error>

    private let timeline: Timeline
    private let networkClient: APIClient
    private let contentDatabase: ContentDatabase

    init(timeline: Timeline, networkClient: APIClient, contentDatabase: ContentDatabase) {
        self.timeline = timeline
        self.networkClient = networkClient
        self.contentDatabase = contentDatabase
        statusSections = contentDatabase.statusesObservation(timeline: timeline)
            .eraseToAnyPublisher()
    }
}

extension TimelineService: StatusListService {
    var filters: AnyPublisher<[Filter], Error> {
        contentDatabase.activeFiltersObservation(date: Date(), context: filterContext)
    }

    func request(maxID: String?, minID: String?) -> AnyPublisher<Never, Error> {
        networkClient.request(Paged(timeline.endpoint, maxID: maxID, minID: minID))
            .map { ($0, timeline) }
            .flatMap(contentDatabase.insert(statuses:timeline:))
            .eraseToAnyPublisher()
    }

    func statusService(status: Status) -> StatusService {
        StatusService(status: status, networkClient: networkClient, contentDatabase: contentDatabase)
    }

    func contextService(status: Status) -> ContextService {
        ContextService(status: status.displayStatus, networkClient: networkClient, contentDatabase: contentDatabase)
    }
}

private extension TimelineService {
    var filterContext: Filter.Context {
        switch timeline {
        case .home, .list:
            return .home
        case .local, .federated, .tag:
            return .public
        }
    }
}
