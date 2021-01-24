// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct SearchService {
    public let sections: AnyPublisher<[CollectionSection], Error>
    public let navigationService: NavigationService
    public let nextPageMaxId: AnyPublisher<String, Never>

    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let nextPageMaxIdSubject = PassthroughSubject<String, Never>()
    private let resultsSubject = PassthroughSubject<Results, Error>()

    init(mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        nextPageMaxId = nextPageMaxIdSubject.eraseToAnyPublisher()
        navigationService = NavigationService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
        sections = resultsSubject.flatMap(contentDatabase.publisher(results:)).eraseToAnyPublisher()
    }
}

extension SearchService: CollectionService {
    public func request(maxId: String?, minId: String?, search: Search?) -> AnyPublisher<Never, Error> {
        guard let search = search else { return Empty().eraseToAnyPublisher() }

        return mastodonAPIClient.request(ResultsEndpoint.search(search))
            .handleEvents(receiveOutput: resultsSubject.send)
            .flatMap(contentDatabase.insert(results:))
            .eraseToAnyPublisher()
    }
}
