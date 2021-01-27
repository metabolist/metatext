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

    private let accountsSubject = CurrentValueSubject<[Account], Error>([])
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
        sections = accountsSubject
            .map { [.init(items: $0.map { CollectionItem.account($0, endpoint.configuration) })] }
            .eraseToAnyPublisher()
        nextPageMaxId = nextPageMaxIdSubject.eraseToAnyPublisher()
        navigationService = NavigationService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }
}

public extension AccountListService {
    func remove(id: Account.Id) {
        accountsSubject.value.removeAll { $0.id == id }
    }
}

extension AccountListService: CollectionService {
    public func request(maxId: String?, minId: String?, search: Search?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.pagedRequest(endpoint, maxId: maxId, minId: minId)
            .handleEvents(receiveOutput: {
                let presentIds = Set(accountsSubject.value.map(\.id))
                accountsSubject.value.append(contentsOf: $0.result.filter { !presentIds.contains($0.id) })

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
