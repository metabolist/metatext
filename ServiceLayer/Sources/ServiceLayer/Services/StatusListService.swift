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
    public let navigationService: NavigationService

    private let filterContext: Filter.Context
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let requestClosure: (_ maxID: String?, _ minID: String?) -> AnyPublisher<Never, Error>
}

extension StatusListService {
    init(timeline: Timeline, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        var title: String?

        if case let .tag(tag) = timeline {
            title = "#".appending(tag)
        }

        let nextPageMaxIDsSubject = PassthroughSubject<String?, Never>()

        self.init(statusSections: contentDatabase.statusesObservation(timeline: timeline),
                  nextPageMaxIDs: nextPageMaxIDsSubject.eraseToAnyPublisher(),
                  contextParentID: nil,
                  title: title,
                  navigationService: NavigationService(
                    status: nil,
                    mastodonAPIClient: mastodonAPIClient,
                    contentDatabase: contentDatabase),
                  filterContext: timeline.filterContext,
                  mastodonAPIClient: mastodonAPIClient,
                  contentDatabase: contentDatabase) { maxID, minID in
            mastodonAPIClient.pagedRequest(timeline.endpoint, maxID: maxID, minID: minID)
                .handleEvents(receiveOutput: { nextPageMaxIDsSubject.send($0.info.maxID) })
                .flatMap { contentDatabase.insert(statuses: $0.result, timeline: timeline) }
                .eraseToAnyPublisher()
        }
    }

    init(statusID: String, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.init(statusSections: contentDatabase.contextObservation(parentID: statusID),
                  nextPageMaxIDs: Empty().eraseToAnyPublisher(),
                  contextParentID: statusID,
                  title: nil,
                  navigationService: NavigationService(
                    status: nil,
                    mastodonAPIClient: mastodonAPIClient,
                    contentDatabase: contentDatabase),
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

public extension StatusListService {
    func request(maxID: String?, minID: String?) -> AnyPublisher<Never, Error> {
        requestClosure(maxID, minID)
    }

    var filters: AnyPublisher<[Filter], Error> {
        contentDatabase.activeFiltersObservation(date: Date(), context: filterContext)
    }
}

private extension Timeline {
    var endpoint: StatusesEndpoint {
        switch self {
        case .home:
            return .timelinesHome
        case .local:
            return .timelinesPublic(local: true)
        case .federated:
            return .timelinesPublic(local: false)
        case let .list(list):
            return .timelinesList(id: list.id)
        case let .tag(tag):
            return .timelinesTag(tag)
        case let .profile(accountId, profileCollection):
            let excludeReplies: Bool
            let onlyMedia: Bool

            switch profileCollection {
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

            return .accountsStatuses(
                id: accountId,
                excludeReplies: excludeReplies,
                onlyMedia: onlyMedia,
                pinned: false)
        }
    }

    var filterContext: Filter.Context {
        switch self {
        case .home, .list:
            return .home
        case .local, .federated, .tag:
            return .public
        case .profile:
            return .account
        }
    }
}
