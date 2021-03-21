// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct TimelineService {
    public let sections: AnyPublisher<[CollectionSection], Error>
    public let navigationService: NavigationService
    public let nextPageMaxId: AnyPublisher<String, Never>
    public let accountIdsForRelationships: AnyPublisher<Set<Account.Id>, Never>
    public let title: AnyPublisher<String, Never>
    public let titleLocalizationComponents: AnyPublisher<[String], Never>
    public let announcesNewItems = true

    private let timeline: Timeline
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let nextPageMaxIdSubject = PassthroughSubject<String, Never>()
    private let accountIdsForRelationshipsSubject = PassthroughSubject<Set<Account.Id>, Never>()

    init(timeline: Timeline,
         environment: AppEnvironment,
         mastodonAPIClient: MastodonAPIClient,
         contentDatabase: ContentDatabase) {
        self.timeline = timeline
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        sections = contentDatabase.timelinePublisher(timeline)
        navigationService = NavigationService(environment: environment,
                                              mastodonAPIClient: mastodonAPIClient,
                                              contentDatabase: contentDatabase)
        nextPageMaxId = nextPageMaxIdSubject.eraseToAnyPublisher()
        accountIdsForRelationships = accountIdsForRelationshipsSubject.eraseToAnyPublisher()

        switch timeline {
        case let .list(list):
            title = Just(list.title).eraseToAnyPublisher()
            titleLocalizationComponents = Empty().eraseToAnyPublisher()
        case let .tag(tag):
            title = Just("#".appending(tag)).eraseToAnyPublisher()
            titleLocalizationComponents = Empty().eraseToAnyPublisher()
        case .favorites:
            title = Empty().eraseToAnyPublisher()
            titleLocalizationComponents = Just(["favorites"]).eraseToAnyPublisher()
        case .bookmarks:
            title = Empty().eraseToAnyPublisher()
            titleLocalizationComponents = Just(["bookmarks"]).eraseToAnyPublisher()
        default:
            title = Empty().eraseToAnyPublisher()
            titleLocalizationComponents = Empty().eraseToAnyPublisher()
        }
    }
}

extension TimelineService: CollectionService {
    public var positionTimeline: Timeline? { timeline }

    public var preferLastPresentIdOverNextPageMaxId: Bool {
        !timeline.ordered
    }

    public func request(maxId: String?, minId: String?, search: Search?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.pagedRequest(timeline.endpoint, maxId: maxId, minId: minId)
            .handleEvents(receiveOutput: {
                if let maxId = $0.info.maxId {
                    nextPageMaxIdSubject.send(maxId)
                }

                accountIdsForRelationshipsSubject.send(
                    Set($0.result.map(\.account.id))
                        .union(Set($0.result.compactMap(\.reblog?.account.id))))
            })
            .flatMap { contentDatabase.insert(statuses: $0.result, timeline: timeline) }
            .eraseToAnyPublisher()
    }
}
