// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct ContextService {
    public let sections: AnyPublisher<[[CollectionItem]], Error>
    public let navigationService: NavigationService
    public var contextParentID: String? { parentID }

    private let parentID: String
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(parentID: String, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.parentID = parentID
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        sections = contentDatabase.contextObservation(parentID: parentID)
        navigationService = NavigationService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }
}

extension ContextService: CollectionService {
    public func request(maxID: String?, minID: String?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(StatusEndpoint.status(id: parentID))
            .flatMap(contentDatabase.insert(status:))
            .merge(with: mastodonAPIClient.request(ContextEndpoint.context(id: parentID))
                    .flatMap { contentDatabase.insert(context: $0, parentID: parentID) })
            .eraseToAnyPublisher()
    }
}
