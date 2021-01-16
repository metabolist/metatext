// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct AccountListService {
    public let sections: AnyPublisher<[[CollectionItem]], Error>
    public let nextPageMaxId: AnyPublisher<String, Never>
    public let navigationService: NavigationService

    private let accountList = CurrentValueSubject<[Account], Error>([])
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
        sections = accountList.map { [$0.map(CollectionItem.account)] }.eraseToAnyPublisher()
        nextPageMaxId = nextPageMaxIdSubject.eraseToAnyPublisher()
        navigationService = NavigationService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }
}

extension AccountListService: CollectionService {
    public func request(maxId: String?, minId: String?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.pagedRequest(endpoint, maxId: maxId, minId: minId)
            .handleEvents(receiveOutput: {
                guard let maxId = $0.info.maxId else { return }

                nextPageMaxIdSubject.send(maxId)
            })
            .flatMap { response in
                contentDatabase.insert(accounts: response.result)
                    .collect()
                    .map { _ in
                        let presentIds = Set(accountList.value.map(\.id))

                        accountList.value += response.result.filter { !presentIds.contains($0.id) }
                    }
            }
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
