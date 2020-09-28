// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct AccountListService {
    public let accountSections: AnyPublisher<[[Account]], Error>
    public let nextPageMaxIDs: AnyPublisher<String?, Never>
    public let navigationService: NavigationService

    private let list: AccountList
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let requestClosure: (_ maxID: String?, _ minID: String?) -> AnyPublisher<Never, Error>
}

extension AccountListService {
    init(favoritedByStatusID statusID: String, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        let list = AccountList()
        let nextPageMaxIDsSubject = PassthroughSubject<String?, Never>()

        self.init(
            accountSections: contentDatabase.accountListObservation(list).map { [$0] }.eraseToAnyPublisher(),
            nextPageMaxIDs: nextPageMaxIDsSubject.eraseToAnyPublisher(),
            navigationService: NavigationService(
                status: nil,
                mastodonAPIClient: mastodonAPIClient,
                contentDatabase: contentDatabase),
            list: list,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase) { maxID, minID -> AnyPublisher<Never, Error> in
            mastodonAPIClient.pagedRequest(
                AccountsEndpoint.statusFavouritedBy(id: statusID), maxID: maxID, minID: minID)
                .handleEvents(receiveOutput: { nextPageMaxIDsSubject.send($0.info.maxID) })
                .flatMap { contentDatabase.append(accounts: $0.result, toList: list) }
                .eraseToAnyPublisher()
        }
    }
}

public extension AccountListService {
    func request(maxID: String?, minID: String?) -> AnyPublisher<Never, Error> {
        requestClosure(maxID, minID)
    }
}
