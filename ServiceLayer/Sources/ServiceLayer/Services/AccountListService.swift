// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct AccountListService {
    public let sections: AnyPublisher<[CollectionSection], Error>
    public let nextPageMaxId: AnyPublisher<String, Never>
    public let navigationService: NavigationService
    public let canRefresh = false

    private let accountsSubject = PassthroughSubject<[Account], Error>()
    private let endpoint: AccountsEndpoint
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let titleComponents: [String]?
    private let nextPageMaxIdSubject = PassthroughSubject<String, Never>()

    init(endpoint: AccountsEndpoint,
         mastodonAPIClient: MastodonAPIClient,
         contentDatabase: ContentDatabase,
         titleComponents: [String]? = nil) {
        self.endpoint = endpoint
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        self.titleComponents = titleComponents
        sections = accountsSubject.scan([]) {
            let presentIds = Set($0.map(\.id))

            return $0 + $1.filter { !presentIds.contains($0.id) }
        }
        .map { [.init(items: $0.map(CollectionItem.account))] }
        .eraseToAnyPublisher()
        nextPageMaxId = nextPageMaxIdSubject.eraseToAnyPublisher()
        navigationService = NavigationService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }
}

extension AccountListService: CollectionService {
    public func request(maxId: String?, minId: String?, search: Search?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.pagedRequest(endpoint, maxId: maxId, minId: minId)
            .handleEvents(receiveOutput: {
                accountsSubject.send($0.result)

                guard let maxId = $0.info.maxId else { return }

                nextPageMaxIdSubject.send(maxId)
            })
            .flatMap { contentDatabase.insert(accounts: $0.result) }
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    public var titleLocalizationComponents: AnyPublisher<[String], Never> {
        if let titleComponents = titleComponents {
            return Just(titleComponents).eraseToAnyPublisher()
        } else {
            return Empty().eraseToAnyPublisher()
        }
    }
}
