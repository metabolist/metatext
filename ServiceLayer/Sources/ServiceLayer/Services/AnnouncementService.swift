// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct AnnouncementService {
    public let announcement: Announcement
    public let navigationService: NavigationService

    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(announcement: Announcement,
         environment: AppEnvironment,
         mastodonAPIClient: MastodonAPIClient,
         contentDatabase: ContentDatabase) {
        self.announcement = announcement
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        navigationService = NavigationService(environment: environment,
                                              mastodonAPIClient: mastodonAPIClient,
                                              contentDatabase: contentDatabase)
    }
}

public extension AnnouncementService {
    func dismiss() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(EmptyEndpoint.dismissAnnouncement(id: announcement.id))
            .flatMap { _ in mastodonAPIClient.request(AnnouncementsEndpoint.announcements) }
            .flatMap(contentDatabase.update(announcements:))
            .eraseToAnyPublisher()
    }

    func addReaction(name: String) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(EmptyEndpoint.addAnnouncementReaction(id: announcement.id, name: name))
            .flatMap { _ in mastodonAPIClient.request(AnnouncementsEndpoint.announcements) }
            .flatMap(contentDatabase.update(announcements:))
            .eraseToAnyPublisher()
    }

    func removeReaction(name: String) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(EmptyEndpoint.removeAnnouncementReaction(id: announcement.id, name: name))
            .flatMap { _ in mastodonAPIClient.request(AnnouncementsEndpoint.announcements) }
            .flatMap(contentDatabase.update(announcements:))
            .eraseToAnyPublisher()
    }
}
