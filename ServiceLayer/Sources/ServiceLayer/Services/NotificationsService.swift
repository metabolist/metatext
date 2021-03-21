// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct NotificationsService {
    public let sections: AnyPublisher<[CollectionSection], Error>
    public let nextPageMaxId: AnyPublisher<String, Never>
    public let navigationService: NavigationService
    public let announcesNewItems = true

    private let excludeTypes: Set<MastodonNotification.NotificationType>
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let nextPageMaxIdSubject: CurrentValueSubject<String, Never>

    init(excludeTypes: Set<MastodonNotification.NotificationType>,
         environment: AppEnvironment,
         mastodonAPIClient: MastodonAPIClient,
         contentDatabase: ContentDatabase) {
        self.excludeTypes = excludeTypes
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase

        let nextPageMaxIdSubject = CurrentValueSubject<String, Never>(String(Int.max))

        self.nextPageMaxIdSubject  = nextPageMaxIdSubject
        sections = contentDatabase.notificationsPublisher(excludeTypes: excludeTypes)
            .handleEvents(receiveOutput: {
                guard case let .notification(notification, _) = $0.last?.items.last,
                      notification.id < nextPageMaxIdSubject.value
                else { return }

                nextPageMaxIdSubject.send(notification.id)
            })
            .eraseToAnyPublisher()
        nextPageMaxId = nextPageMaxIdSubject.eraseToAnyPublisher()
        navigationService = NavigationService(environment: environment,
                                              mastodonAPIClient: mastodonAPIClient,
                                              contentDatabase: contentDatabase)
    }
}

extension NotificationsService: CollectionService {
    public var markerTimeline: Marker.Timeline? { excludeTypes.isEmpty ? .notifications : nil }

    public func request(maxId: String?, minId: String?, search: Search?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.pagedRequest(NotificationsEndpoint.notifications(excludeTypes: excludeTypes),
                                       maxId: maxId,
                                       minId: minId)
            .handleEvents(receiveOutput: {
                guard let maxId = $0.info.maxId, maxId < nextPageMaxIdSubject.value else { return }

                nextPageMaxIdSubject.send(maxId)
            })
            .flatMap { contentDatabase.insert(notifications: $0.result) }
            .eraseToAnyPublisher()
    }

    public func requestMarkerLastReadId() -> AnyPublisher<CollectionItem.Id, Error> {
        mastodonAPIClient.request(MarkersEndpoint.get([.notifications]))
            .compactMap { $0.values.first?.lastReadId }
            .eraseToAnyPublisher()
    }

    public func setMarkerLastReadId(_ id: CollectionItem.Id) -> AnyPublisher<CollectionItem.Id, Error> {
        mastodonAPIClient.request(MarkersEndpoint.post([.notifications: id]))
            .compactMap { $0.values.first?.lastReadId }
            .eraseToAnyPublisher()
    }
}
