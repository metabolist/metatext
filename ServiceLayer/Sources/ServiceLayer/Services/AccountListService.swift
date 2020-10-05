// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct AccountListService {
    public let sections: AnyPublisher<[[CollectionItem]], Error>
    public let nextPageMaxIDs: AnyPublisher<String, Never>
    public let navigationService: NavigationService

    private let list: AccountList
    private let endpoint: AccountsEndpoint
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let nextPageMaxIDsSubject = PassthroughSubject<String, Never>()

    init(endpoint: AccountsEndpoint, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        list = AccountList()
        self.endpoint = endpoint
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        sections = contentDatabase.accountListObservation(list)
            .map { [$0.map(CollectionItem.account)] }
            .eraseToAnyPublisher()
        nextPageMaxIDs = nextPageMaxIDsSubject.eraseToAnyPublisher()
        navigationService = NavigationService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }
}

extension AccountListService: CollectionService {
    public func request(maxID: String?, minID: String?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.pagedRequest(endpoint, maxID: maxID, minID: minID)
            .handleEvents(receiveOutput: {
                guard let maxID = $0.info.maxID else { return }

                nextPageMaxIDsSubject.send(maxID)
            })
            .flatMap { contentDatabase.append(accounts: $0.result, toList: list) }
            .eraseToAnyPublisher()
    }
}
