// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct ContextService {
    public let sections: AnyPublisher<[[CollectionItem]], Error>
    public let navigationService: NavigationService

    private let id: Status.Id
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(id: Status.Id, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.id = id
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        sections = contentDatabase.contextPublisher(id: id)
        navigationService = NavigationService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }
}

extension ContextService: CollectionService {
    public func request(maxId: String?, minId: String?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(StatusEndpoint.status(id: id))
            .flatMap(contentDatabase.insert(status:))
            .merge(with: mastodonAPIClient.request(ContextEndpoint.context(id: id))
                    .flatMap { contentDatabase.insert(context: $0, parentId: id) })
            .eraseToAnyPublisher()
    }

    public func expand(ids: Set<Status.Id>) -> AnyPublisher<Never, Error> {
        contentDatabase.expand(ids: ids)
    }

    public func collapse(ids: Set<Status.Id>) -> AnyPublisher<Never, Error> {
        contentDatabase.collapse(ids: ids)
    }
}
