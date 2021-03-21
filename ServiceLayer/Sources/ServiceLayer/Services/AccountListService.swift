// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct AccountListService {
    public let sections: AnyPublisher<[CollectionSection], Error>
    public let nextPageMaxId: AnyPublisher<String, Never>
    public let accountIdsForRelationships: AnyPublisher<Set<Account.Id>, Never>
    public let navigationService: NavigationService
    public let canRefresh = false

    private let listId = UUID().uuidString
    private let endpoint: AccountsEndpoint
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let titleComponents: [String]?
    private let nextPageMaxIdSubject = PassthroughSubject<String, Never>()
    private let accountIdsForRelationshipsSubject = PassthroughSubject<Set<Account.Id>, Never>()

    init(endpoint: AccountsEndpoint,
         environment: AppEnvironment,
         mastodonAPIClient: MastodonAPIClient,
         contentDatabase: ContentDatabase,
         titleComponents: [String]? = nil) {
        self.endpoint = endpoint
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        self.titleComponents = titleComponents
        sections = contentDatabase.accountListPublisher(id: listId, configuration: endpoint.configuration)
        nextPageMaxId = nextPageMaxIdSubject.eraseToAnyPublisher()
        accountIdsForRelationships = accountIdsForRelationshipsSubject.eraseToAnyPublisher()
        navigationService = NavigationService(environment: environment,
                                              mastodonAPIClient: mastodonAPIClient,
                                              contentDatabase: contentDatabase)
    }
}

public extension AccountListService {
    func remove(id: Account.Id) -> AnyPublisher<Never, Error> {
        contentDatabase.remove(id: id, from: listId)
    }
}

extension AccountListService: CollectionService {
    public func request(maxId: String?, minId: String?, search: Search?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.pagedRequest(endpoint, maxId: maxId, minId: minId)
            .handleEvents(receiveOutput: {
                accountIdsForRelationshipsSubject.send(Set($0.result.map(\.id)))

                guard let maxId = $0.info.maxId else { return }

                nextPageMaxIdSubject.send(maxId)
            })
            .flatMap { contentDatabase.insert(accounts: $0.result, listId: listId) }
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
