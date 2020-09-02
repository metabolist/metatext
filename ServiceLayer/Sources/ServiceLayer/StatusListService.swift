// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon

public struct StatusListService {
    public let statusSections: AnyPublisher<[[Status]], Error>
    public let paginates: Bool
    public let contextParentID: String?

    private let filterContext: Filter.Context
    private let networkClient: APIClient
    private let contentDatabase: ContentDatabase
    private let requestClosure: (_ maxID: String?, _ minID: String?) -> AnyPublisher<Never, Error>
}

extension StatusListService {
    init(timeline: Timeline, networkClient: APIClient, contentDatabase: ContentDatabase) {
        let filterContext: Filter.Context

        switch timeline {
        case .home, .list:
            filterContext = .home
        case .local, .federated, .tag:
            filterContext = .public
        }

        self.init(statusSections: contentDatabase.statusesObservation(timeline: timeline),
                  paginates: true,
                  contextParentID: nil,
                  filterContext: filterContext,
                  networkClient: networkClient,
                  contentDatabase: contentDatabase) { maxID, minID in
            networkClient.request(Paged(timeline.endpoint, maxID: maxID, minID: minID))
                .map { ($0, timeline) }
                .flatMap(contentDatabase.insert(statuses:timeline:))
                .eraseToAnyPublisher()
        }
    }
}

public extension StatusListService {
    func request(maxID: String?, minID: String?) -> AnyPublisher<Never, Error> {
        requestClosure(maxID, minID)
    }

    var filters: AnyPublisher<[Filter], Error> {
        contentDatabase.activeFiltersObservation(date: Date(), context: filterContext)
    }

    func statusService(status: Status) -> StatusService {
        StatusService(status: status, networkClient: networkClient, contentDatabase: contentDatabase)
    }

    func contextService(statusID: String) -> Self {
        Self(statusSections: contentDatabase.contextObservation(parentID: statusID),
             paginates: false,
             contextParentID: statusID,
             filterContext: .thread,
             networkClient: networkClient,
             contentDatabase: contentDatabase) { _, _ in
            Publishers.Merge(
                networkClient.request(StatusEndpoint.status(id: statusID))
                    .map { ([$0], nil) }
                    .flatMap(contentDatabase.insert(statuses:timeline:))
                    .eraseToAnyPublisher(),
                networkClient.request(ContextEndpoint.context(id: statusID))
                    .map { ($0, statusID) }
                    .flatMap(contentDatabase.insert(context:parentID:))
                    .eraseToAnyPublisher())
                .eraseToAnyPublisher()
        }
    }
}
