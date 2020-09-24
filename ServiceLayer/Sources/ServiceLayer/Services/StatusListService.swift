// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct StatusListService {
    public let statusSections: AnyPublisher<[[Status]], Error>
    public let nextPageMaxIDs: AnyPublisher<String?, Never>
    public let contextParentID: String?
    public let title: String?

    private let filterContext: Filter.Context
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let requestClosure: (_ maxID: String?, _ minID: String?) -> AnyPublisher<Never, Error>
}

extension StatusListService {
    init(timeline: Timeline, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        let filterContext: Filter.Context

        switch timeline {
        case .home, .list:
            filterContext = .home
        case .local, .federated, .tag:
            filterContext = .public
        }

        var title: String?

        if case let .tag(tag) = timeline {
            title = "#".appending(tag)
        }

        let nextPageMaxIDsSubject = PassthroughSubject<String?, Never>()

        self.init(statusSections: contentDatabase.statusesObservation(timeline: timeline),
                  nextPageMaxIDs: nextPageMaxIDsSubject.eraseToAnyPublisher(),
                  contextParentID: nil,
                  title: title,
                  filterContext: filterContext,
                  mastodonAPIClient: mastodonAPIClient,
                  contentDatabase: contentDatabase) { maxID, minID in
            mastodonAPIClient.pagedRequest(timeline.endpoint, maxID: maxID, minID: minID)
                .handleEvents(receiveOutput: { nextPageMaxIDsSubject.send($0.info.maxID) })
                .flatMap { contentDatabase.insert(statuses: $0.result, timeline: timeline) }
                .eraseToAnyPublisher()
        }
    }

    init(
        accountID: String,
        collection: CurrentValueSubject<AccountStatusCollection, Never>,
        mastodonAPIClient: MastodonAPIClient,
        contentDatabase: ContentDatabase) {
        let nextPageMaxIDsSubject = PassthroughSubject<String?, Never>()

        self.init(
            statusSections: collection
                .flatMap { contentDatabase.statusesObservation(accountID: accountID, collection: $0) }
                .eraseToAnyPublisher(),
            nextPageMaxIDs: nextPageMaxIDsSubject.eraseToAnyPublisher(),
            contextParentID: nil,
            title: nil,
            filterContext: .account,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase) { maxID, minID in
            let excludeReplies: Bool
            let onlyMedia: Bool

            switch collection.value {
            case .statuses:
                excludeReplies = true
                onlyMedia = false
            case .statusesAndReplies:
                excludeReplies = false
                onlyMedia = false
            case .media:
                excludeReplies = true
                onlyMedia = true
            }

            let endpoint = StatusesEndpoint.accountsStatuses(
                id: accountID,
                excludeReplies: excludeReplies,
                onlyMedia: onlyMedia,
                pinned: false)
            return mastodonAPIClient.pagedRequest(endpoint, maxID: maxID, minID: minID)
                .handleEvents(receiveOutput: { nextPageMaxIDsSubject.send($0.info.maxID) })
                .flatMap { contentDatabase.insert(statuses: $0.result, accountID: accountID, collection: collection.value) }
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
        StatusService(status: status, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func service(timeline: Timeline) -> Self {
        Self(timeline: timeline, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func service(accountID: String) -> AccountStatusesService {
        AccountStatusesService(id: accountID, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func contextService(statusID: String) -> Self {
        Self(statusSections: contentDatabase.contextObservation(parentID: statusID),
             nextPageMaxIDs: Empty().eraseToAnyPublisher(),
             contextParentID: statusID,
             title: nil,
             filterContext: .thread,
             mastodonAPIClient: mastodonAPIClient,
             contentDatabase: contentDatabase) { _, _ in
            Publishers.Merge(
                mastodonAPIClient.request(StatusEndpoint.status(id: statusID))
                    .flatMap(contentDatabase.insert(status:))
                    .eraseToAnyPublisher(),
                mastodonAPIClient.request(ContextEndpoint.context(id: statusID))
                    .flatMap { contentDatabase.insert(context: $0, parentID: statusID) }
                    .eraseToAnyPublisher())
                .eraseToAnyPublisher()
        }
    }
}
