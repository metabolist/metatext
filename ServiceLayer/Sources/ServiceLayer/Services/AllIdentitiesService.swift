// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI
import Secrets

public struct AllIdentitiesService {
    public let mostRecentlyUsedIdentityID: AnyPublisher<UUID?, Never>

    private let identityDatabase: IdentityDatabase
    private let environment: AppEnvironment

    public init(environment: AppEnvironment) throws {
        self.identityDatabase = try IdentityDatabase(inMemory: environment.inMemoryContent,
                                                     fixture: environment.identityFixture,
                                                     keychain: environment.keychain)
        self.environment = environment

        mostRecentlyUsedIdentityID = identityDatabase.mostRecentlyUsedIdentityIDObservation()
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
}

public extension AllIdentitiesService {
    func identityService(id: UUID) throws -> IdentityService {
        try IdentityService(identityID: id,
                            identityDatabase: identityDatabase,
                            environment: environment)
    }

    func createIdentity(id: UUID, instanceURL: URL) -> AnyPublisher<Never, Error> {
        identityDatabase.createIdentity(id: id, url: instanceURL)
    }

    func authorizeIdentity(id: UUID, instanceURL: URL) -> AnyPublisher<Never, Error> {
        let secrets = Secrets(identityID: id, keychain: environment.keychain)
        let authenticationService = AuthenticationService(environment: environment)

        return authenticationService.authorizeApp(instanceURL: instanceURL)
            .tryMap { appAuthorization -> (URL, AppAuthorization) in
                try secrets.setClientID(appAuthorization.clientId)
                try secrets.setClientSecret(appAuthorization.clientSecret)

                return (instanceURL, appAuthorization)
            }
            .flatMap(authenticationService.authenticate(instanceURL:appAuthorization:))
            .tryMap { try secrets.setAccessToken($0.accessToken) }
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func deleteIdentity(_ identity: Identity) -> AnyPublisher<Never, Error> {
        let secrets = Secrets(identityID: identity.id, keychain: environment.keychain)
        let mastodonAPIClient = MastodonAPIClient(session: environment.session)

        mastodonAPIClient.instanceURL = identity.url

        return identityDatabase.deleteIdentity(id: identity.id)
            .collect()
            .tryMap { _ in
                DeletionEndpoint.oauthRevoke(
                    token: try secrets.getAccessToken(),
                    clientID: try secrets.getClientID(),
                    clientSecret: try secrets.getClientSecret())
            }
            .flatMap(mastodonAPIClient.request)
            .collect()
            .tryMap { _ in
                try secrets.deleteAllItems()
                try ContentDatabase.delete(forIdentityID: identity.id)
            }
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func updatePushSubscriptions(deviceToken: String) -> AnyPublisher<Never, Error> {
        identityDatabase.identitiesWithOutdatedDeviceTokens(deviceToken: deviceToken)
            .tryMap { identities -> [AnyPublisher<Never, Never>] in
                try identities.map {
                    try identityService(id: $0.id)
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
