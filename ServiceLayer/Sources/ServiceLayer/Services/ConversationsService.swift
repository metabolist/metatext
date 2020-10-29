// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct ConversationsService {
    public let sections: AnyPublisher<[[CollectionItem]], Error>
    public let nextPageMaxId: AnyPublisher<String, Never>
    public let navigationService: NavigationService

    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let nextPageMaxIdSubject = PassthroughSubject<String, Never>()

    init(mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        sections = contentDatabase.conversationsPublisher()
            .map { [$0.map(CollectionItem.conversation)] }
            .eraseToAnyPublisher()
        nextPageMaxId = nextPageMaxIdSubject.eraseToAnyPublisher()
        navigationService = NavigationService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }
}

extension ConversationsService: CollectionService {
    public func request(maxId: String?, minId: String?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.pagedRequest(ConversationsEndpoint.conversations, maxId: maxId, minId: minId)
            .handleEvents(receiveOutput: {
                guard let maxId = $0.info.maxId else { return }

                nextPageMaxIdSubject.send(maxId)
            })
            .flatMap { contentDatabase.insert(conversations: $0.result) }
            .eraseToAnyPublisher()
    }
}
