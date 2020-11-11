// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct ProfileService {
    public let accountServicePublisher: AnyPublisher<AccountService, Error>

    private let id: Account.Id
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(account: Account, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.init(
            id: account.id,
            account: account,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
    }

    init(id: Account.Id, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.init(id: id, account: nil, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    private init(
        id: Account.Id,
        account: Account?,
        mastodonAPIClient: MastodonAPIClient,
        contentDatabase: ContentDatabase) {
        self.id = id
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase

        var accountPublisher = contentDatabase.profilePublisher(id: id)

        if let account = account {
            accountPublisher = accountPublisher
                .merge(with: Just(Profile(account: account)).setFailureType(to: Error.self))
                .removeDuplicates()
                .eraseToAnyPublisher()
        }

        accountServicePublisher = accountPublisher
            .map {
                AccountService(
                    account: $0.account,
                    relationship: $0.relationship,
                    identityProofs: $0.identityProofs,
                    mastodonAPIClient: mastodonAPIClient,
                    contentDatabase: contentDatabase)
            }
            .eraseToAnyPublisher()
    }
}

public extension ProfileService {
    func timelineService(profileCollection: ProfileCollection) -> TimelineService {
        TimelineService(
            timeline: .profile(accountId: id, profileCollection: profileCollection),
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
    }

    func fetchProfile() -> AnyPublisher<Never, Error> {
        Publishers.Merge3(
            mastodonAPIClient.request(AccountEndpoint.accounts(id: id))
                .flatMap { contentDatabase.insert(account: $0) },
            mastodonAPIClient.request(RelationshipsEndpoint.relationships(ids: [id]))
                .flatMap { contentDatabase.insert(relationships: $0) },
            mastodonAPIClient.request(IdentityProofsEndpoint.identityProofs(id: id))
                .catch { _ in Empty() }
                .flatMap { contentDatabase.insert(identityProofs: $0, id: id) })
            .eraseToAnyPublisher()
    }

    func fetchPinnedStatuses() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(
            StatusesEndpoint.accountsStatuses(
                id: id,
                excludeReplies: true,
                onlyMedia: false,
                pinned: true))
            .flatMap { contentDatabase.insert(pinnedStatuses: $0, accountId: id) }
            .eraseToAnyPublisher()
    }
}
