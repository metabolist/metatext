// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct AccountService {
    public let account: Account
    public let navigationService: NavigationService

    private let environment: AppEnvironment
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    public init(account: Account,
                identityProofs: [IdentityProof] = [],
                featuredTags: [FeaturedTag] = [],
                environment: AppEnvironment,
                mastodonAPIClient: MastodonAPIClient,
                contentDatabase: ContentDatabase) {
        self.account = account
        navigationService = NavigationService(environment: environment,
                                              mastodonAPIClient: mastodonAPIClient,
                                              contentDatabase: contentDatabase)
        self.environment = environment
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
    }
}

public extension AccountService {
    var isLocal: Bool {
        URL(string: account.url)?.host == mastodonAPIClient.instanceURL.host
    }

    var domain: String? { URL(string: account.url)?.host }

    func lists() -> AnyPublisher<[List], Error> {
        mastodonAPIClient.request(ListsEndpoint.listsWithAccount(id: account.id))
    }

    func addToList(id: List.Id) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(EmptyEndpoint.addAccountsToList(id: id, accountIds: [account.id]))
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func removeFromList(id: List.Id) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(EmptyEndpoint.removeAccountsFromList(id: id, accountIds: [account.id]))
            .ignoreOutput()
            .eraseToAnyPublisher()
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

    func notify() -> AnyPublisher<Never, Error> {
        relationshipAction(.accountsFollow(id: account.id, notify: true))
    }

    func unnotify() -> AnyPublisher<Never, Error> {
        relationshipAction(.accountsFollow(id: account.id, notify: false))
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

    func mute(notifications: Bool, duration: Int) -> AnyPublisher<Never, Error> {
        relationshipAction(.accountsMute(id: account.id, notifications: notifications, duration: duration))
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

    func acceptFollowRequest() -> AnyPublisher<Never, Error> {
        relationshipAction(.acceptFollowRequest(id: account.id))
    }

    func rejectFollowRequest() -> AnyPublisher<Never, Error> {
        relationshipAction(.rejectFollowRequest(id: account.id))
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
            environment: environment,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase,
            titleComponents: ["account.followed-by-%@", "@".appending(account.acct)])
    }

    func followersService() -> AccountListService {
        AccountListService(
            endpoint: .accountsFollowers(id: account.id),
            environment: environment,
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
