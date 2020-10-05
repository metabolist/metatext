// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct ContextService {
    public let sections: AnyPublisher<[[CollectionItem]], Error>
    public let navigationService: NavigationService
    public let nextPageMaxIDs: AnyPublisher<String?, Never> = Empty().eraseToAnyPublisher()
    public let title: String? = nil
    public var contextParentID: String? { statusID }

    private let statusID: String
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(statusID: String, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.statusID = statusID
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        sections = contentDatabase.contextObservation(parentID: statusID)
        navigationService = NavigationService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }
}

extension ContextService: CollectionService {
    public func request(maxID: String?, minID: String?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(StatusEndpoint.status(id: statusID))
            .flatMap(contentDatabase.insert(status:))
            .merge(with: mastodonAPIClient.request(ContextEndpoint.context(id: statusID))
                    .flatMap { contentDatabase.insert(context: $0, parentID: statusID) })
            .eraseToAnyPublisher()
    }
}
