// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI
import Secrets

public struct AllIdentitiesService {
    private let environment: AppEnvironment
    private let database: IdentityDatabase

    public init(environment: AppEnvironment) throws {
        self.environment = environment
        self.database =  try environment.fixtureDatabase ?? IdentityDatabase(
            inMemory: environment.inMemoryContent,
            keychain: environment.keychain)
    }
}

public extension AllIdentitiesService {
    func identityService(id: UUID) throws -> IdentityService {
        try IdentityService(id: id, database: database, environment: environment)
    }

    func immediateMostRecentlyUsedIdentityIDObservation() -> AnyPublisher<UUID?, Error> {
        database.immediateMostRecentlyUsedIdentityIDObservation()
    }

    func createIdentity(id: UUID, url: URL, authenticated: Bool) -> AnyPublisher<Never, Error> {
        createIdentity(
            id: id,
            url: url,
            authenticationPublisher: authenticated
                ? AuthenticationService(url: url, environment: environment).authenticate()
                : nil)
    }

    func createIdentity(id: UUID, url: URL, registration: Registration) -> AnyPublisher<Never, Error> {
        createIdentity(
            id: id,
            url: url,
            authenticationPublisher: AuthenticationService(url: url, environment: environment)
                .register(registration))
    }

    func deleteIdentity(id: UUID) -> AnyPublisher<Never, Error> {
        database.deleteIdentity(id: id)
            .collect()
            .tryMap { _ -> AnyPublisher<Never, Error> in
                try ContentDatabase.delete(forIdentityID: id)

                let secrets = Secrets(identityID: id, keychain: environment.keychain)

                defer { secrets.deleteAllItems() }

                do {
                    return MastodonAPIClient(
                        session: environment.session,
                        instanceURL: try secrets.getInstanceURL())
                        .request(DeletionEndpoint.oauthRevoke(
                                    token: try secrets.getAccessToken(),
                                    clientID: try secrets.getClientID(),
                                    clientSecret: try secrets.getClientSecret()))
                        .ignoreOutput()
                        .eraseToAnyPublisher()
                } catch {
                    return Empty().eraseToAnyPublisher()
                }
            }
            .flatMap { $0 }
            .eraseToAnyPublisher()
    }

    func updatePushSubscriptions(deviceToken: Data) -> AnyPublisher<Never, Error> {
        database.identitiesWithOutdatedDeviceTokens(deviceToken: deviceToken)
            .tryMap { identities -> [AnyPublisher<Never, Never>] in
                try identities.map {
                    try IdentityService(id: $0.id, database: database, environment: environment)
                        .createPushSubscription(deviceToken: deviceToken, alerts: $0.pushSubscriptionAlerts)
                        .catch { _ in Empty() } // don't want to disrupt pipeline
                        .eraseToAnyPublisher()
                }
            }
            .map(Publishers.MergeMany.init)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }
}

private extension AllIdentitiesService {
    func createIdentity(
        id: UUID,
        url: URL,
        authenticationPublisher: AnyPublisher<(AppAuthorization, AccessToken), Error>?) -> AnyPublisher<Never, Error> {
        let secrets = Secrets(identityID: id, keychain: environment.keychain)

        do {
            try secrets.setInstanceURL(url)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        let createIdentityPublisher = database.createIdentity(
            id: id,
            url: url,
            authenticated: authenticationPublisher != nil)
            .ignoreOutput()
            .eraseToAnyPublisher()

        if let authenticationPublisher = authenticationPublisher {
            return authenticationPublisher
                .tryMap {
                    try secrets.setClientID($0.clientId)
                    try secrets.setClientSecret($0.clientSecret)
                    try secrets.setAccessToken($1.accessToken)
                }
                .flatMap { createIdentityPublisher }
                .eraseToAnyPublisher()
        } else {
            return createIdentityPublisher
        }
    }
}
