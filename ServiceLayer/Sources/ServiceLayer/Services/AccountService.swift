// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct AccountService {
    public let account: Account
    public let relationship: Relationship?
    public let identityProofs: [IdentityProof]
    public let navigationService: NavigationService

    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(account: Account,
         relationship: Relationship? = nil,
         identityProofs: [IdentityProof] = [],
         mastodonAPIClient: MastodonAPIClient,
         contentDatabase: ContentDatabase) {
        self.account = account
        self.relationship = relationship
        self.identityProofs = identityProofs
        navigationService = NavigationService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
    }
}

public extension AccountService {
    func follow() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(RelationshipEndpoint.accountsFollow(id: account.id))
            .flatMap { contentDatabase.insert(relationships: [$0]) }
            .eraseToAnyPublisher()
    }

    func unfollow() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(RelationshipEndpoint.accountsUnfollow(id: account.id))
            .flatMap {
                contentDatabase.insert(relationships: [$0])
                    .merge(with: contentDatabase.unfollow(id: account.id))
            }
            .eraseToAnyPublisher()
    }
}
