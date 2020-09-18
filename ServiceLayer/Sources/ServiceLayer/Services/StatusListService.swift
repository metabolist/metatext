// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct StatusListService {
    public let statusSections: AnyPublisher<[[Status]], Error>
    public let paginates: Bool
    public let contextParentID: String?
    public var title: String?

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

        self.init(statusSections: contentDatabase.statusesObservation(timeline: timeline),
                  paginates: true,
                  contextParentID: nil,
                  title: title,
                  filterContext: filterContext,
                  mastodonAPIClient: mastodonAPIClient,
                  contentDatabase: contentDatabase) { maxID, minID in
            mastodonAPIClient.request(Paged(timeline.endpoint, maxID: maxID, minID: minID))
                .flatMap { contentDatabase.insert(statuses: $0, timeline: timeline) }
                .eraseToAnyPublisher()
        }
    }

    init(
        accountID: String,
        collection: AnyPublisher<AccountStatusCollection, Never>,
        mastodonAPIClient: MastodonAPIClient,
        contentDatabase: ContentDatabase) {
        self.init(
            statusSections: collection
                .flatMap { contentDatabase.statusesObservation(accountID: accountID, collection: $0) }
                .eraseToAnyPublisher(),
            paginates: true,
            contextParentID: nil,
            title: "turn this into a closure or publisher",
            filterContext: .account,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase) { maxID, minID in
            Just((maxID, minID)).combineLatest(collection).flatMap { params -> AnyPublisher<Never, Error> in
                let ((maxID, minID), collection) = params
                let excludeReplies: Bool
                let onlyMedia: Bool

                switch collection {
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
                return mastodonAPIClient.request(Paged(endpoint, maxID: maxID, minID: minID))
                    .flatMap { contentDatabase.insert(statuses: $0, accountID: accountID, collection: collection) }
                    .eraseToAnyPublisher()
            }
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
             paginates: false,
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
