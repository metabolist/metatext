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

    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let nextPageMaxIdSubject: CurrentValueSubject<String, Never>

    init(mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase

        let nextPageMaxIdSubject = CurrentValueSubject<String, Never>(String(Int.max))

        self.nextPageMaxIdSubject  = nextPageMaxIdSubject
        sections = contentDatabase.notificationsPublisher()
            .handleEvents(receiveOutput: {
                guard case let .notification(notification, _) = $0.last?.items.last,
                      notification.id < nextPageMaxIdSubject.value
                else { return }

                nextPageMaxIdSubject.send(notification.id)
            })
            .eraseToAnyPublisher()
        nextPageMaxId = nextPageMaxIdSubject.eraseToAnyPublisher()
        navigationService = NavigationService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }
}

extension NotificationsService: CollectionService {
    public var markerTimeline: Marker.Timeline? { .notifications }

    public func request(maxId: String?, minId: String?, search: Search?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.pagedRequest(NotificationsEndpoint.notifications, maxId: maxId, minId: minId)
            .handleEvents(receiveOutput: {
                guard let maxId = $0.info.maxId, maxId < nextPageMaxIdSubject.value else { return }

                nextPageMaxIdSubject.send(maxId)
            })
            .flatMap { contentDatabase.insert(notifications: $0.result) }
            .eraseToAnyPublisher()
    }
}
