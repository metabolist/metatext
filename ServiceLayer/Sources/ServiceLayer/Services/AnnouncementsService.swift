// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import MastodonAPI

public struct AnnouncementsService {
    public let sections: AnyPublisher<[CollectionSection], Error>
    public let navigationService: NavigationService
    public let titleLocalizationComponents: AnyPublisher<[String], Never>

    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(environment: AppEnvironment, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        sections = contentDatabase.announcementsPublisher()
        navigationService = NavigationService(environment: environment,
                                              mastodonAPIClient: mastodonAPIClient,
                                              contentDatabase: contentDatabase)
        titleLocalizationComponents = Just(["main-navigation.announcements"]).eraseToAnyPublisher()
    }
}

extension AnnouncementsService: CollectionService {
    public func request(maxId: String?, minId: String?, search: Search?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(AnnouncementsEndpoint.announcements)
            .flatMap(contentDatabase.update(announcements:))
            .eraseToAnyPublisher()
    }
}
