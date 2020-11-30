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

    public init(account: Account,
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
    var isLocal: Bool {
        account.url.host == mastodonAPIClient.instanceURL.host
    }

    func follow() -> AnyPublisher<Never, Error> {
        relationshipAction(.accountsFollow(id: account.id))
    }

    func unfollow() -> AnyPublisher<Never, Error> {
        relationshipAction(.accountsUnfollow(id: account.id))
            .collect()
            .flatMap { _ in contentDatabase.unfollow(id: account.id) }
            .eraseToAnyPublisher()
    }

    func hideReblogs() -> AnyPublisher<Never, Error> {
        relationshipAction(.accountsFollow(id: account.id, showReblogs: false))
    }

    func showReblogs() -> AnyPublisher<Never, Error> {
        relationshipAction(.accountsFollow(id: account.id, showReblogs: true))
    }

    func block() -> AnyPublisher<Never, Error> {
        relationshipAction(.accountsBlock(id: account.id))
            .collect()
            .flatMap { _ in contentDatabase.block(id: account.id) }
            .eraseToAnyPublisher()
    }

    func unblock() -> AnyPublisher<Never, Error> {
        relationshipAction(.accountsUnblock(id: account.id))
    }

    func mute() -> AnyPublisher<Never, Error> {
        relationshipAction(.accountsMute(id: account.id))
            .collect()
            .flatMap { _ in contentDatabase.mute(id: account.id) }
            .eraseToAnyPublisher()
    }

    func unmute() -> AnyPublisher<Never, Error> {
        relationshipAction(.accountsUnmute(id: account.id))
    }

    func pin() -> AnyPublisher<Never, Error> {
        relationshipAction(.accountsPin(id: account.id))
    }

    func unpin() -> AnyPublisher<Never, Error> {
        relationshipAction(.accountsUnpin(id: account.id))
    }

    func set(note: String) -> AnyPublisher<Never, Error> {
        relationshipAction(.note(note, id: account.id))
    }

    func report(_ elements: ReportElements) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(ReportEndpoint.create(elements)).ignoreOutput().eraseToAnyPublisher()
    }
}

private extension AccountService {
    func relationshipAction(_ endpoint: RelationshipEndpoint) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(endpoint)
            .flatMap { contentDatabase.insert(relationships: [$0]) }
            .eraseToAnyPublisher()
    }
}
