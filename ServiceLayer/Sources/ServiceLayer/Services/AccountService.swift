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
    public let featuredTags: [FeaturedTag]
    public let navigationService: NavigationService

    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    public init(account: Account,
                relationship: Relationship? = nil,
                identityProofs: [IdentityProof] = [],
                featuredTags: [FeaturedTag] = [],
                mastodonAPIClient: MastodonAPIClient,
                contentDatabase: ContentDatabase) {
        self.account = account
        self.relationship = relationship
        self.identityProofs = identityProofs
        self.featuredTags = featuredTags
        navigationService = NavigationService(mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
    }
}

public extension AccountService {
    var isLocal: Bool {
        account.url.host == mastodonAPIClient.instanceURL.host
    }

    var domain: String? { account.url.host }

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

    func domainBlock() -> AnyPublisher<Never, Error> {
        guard let domain = domain else { return Fail(error: URLError(.badURL)).eraseToAnyPublisher() }

        return domainAction(EmptyEndpoint.blockDomain(domain))
    }

    func domainUnblock() -> AnyPublisher<Never, Error> {
        guard let domain = domain else { return Fail(error: URLError(.badURL)).eraseToAnyPublisher() }

        return domainAction(EmptyEndpoint.unblockDomain(domain))
    }

    func followingService() -> AccountListService {
        AccountListService(
            endpoint: .accountsFollowing(id: account.id),
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase,
            titleComponents: ["account.followed-by-%@", "@".appending(account.acct)])
    }

    func followersService() -> AccountListService {
        AccountListService(
            endpoint: .accountsFollowers(id: account.id),
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase,
            titleComponents: ["account.%@-followers", "@".appending(account.acct)])
    }
}

private extension AccountService {
    func relationshipAction(_ endpoint: RelationshipEndpoint) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(endpoint)
            .flatMap { contentDatabase.insert(relationships: [$0]) }
            .eraseToAnyPublisher()
    }

    func domainAction(_ endpoint: EmptyEndpoint) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(endpoint)
            .flatMap { _ in mastodonAPIClient.request(RelationshipsEndpoint.relationships(ids: [account.id])) }
            .flatMap { contentDatabase.insert(relationships: $0) }
            .ignoreOutput()
            .eraseToAnyPublisher()
    }
}
