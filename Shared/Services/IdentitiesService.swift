// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class IdentitiesService {
    @Published var mostRecentlyUsedIdentityID: UUID?

    private let identityDatabase: IdentityDatabase
    private let environment: AppEnvironment

    init(identityDatabase: IdentityDatabase, environment: AppEnvironment) {
        self.identityDatabase = identityDatabase
        self.environment = environment

        identityDatabase.mostRecentlyUsedIdentityIDObservation()
            .replaceError(with: nil)
            .assign(to: &$mostRecentlyUsedIdentityID)
    }
}

extension IdentitiesService {
    func identityService(id: UUID) throws -> IdentityService {
        try IdentityService(identityID: id,
                            identityDatabase: identityDatabase,
                            environment: environment)
    }

    func createIdentity(id: UUID, instanceURL: URL) -> AnyPublisher<Void, Error> {
        identityDatabase.createIdentity(id: id, url: instanceURL)
    }

    func authorizeIdentity(id: UUID, instanceURL: URL) -> AnyPublisher<Void, Error> {
        let secretsService = SecretsService(identityID: id, keychainService: environment.keychainServiceType)
        let authenticationService = AuthenticationService(environment: environment)

        return authenticationService.authorizeApp(instanceURL: instanceURL)
            .tryMap { appAuthorization -> (URL, AppAuthorization) in
                try secretsService.set(appAuthorization.clientId, forItem: .clientID)
                try secretsService.set(appAuthorization.clientSecret, forItem: .clientSecret)

                return (instanceURL, appAuthorization)
            }
            .flatMap(authenticationService.authenticate(instanceURL:appAuthorization:))
            .tryMap { accessToken -> Void in
                try secretsService.set(accessToken.accessToken, forItem: .accessToken)

                return ()
            }
            .eraseToAnyPublisher()
    }

    func deleteIdentity(_ identity: Identity) -> AnyPublisher<Void, Error> {
        let secretsService = SecretsService(identityID: identity.id, keychainService: environment.keychainServiceType)
        let networkClient = MastodonClient(environment: environment)

        networkClient.instanceURL = identity.url

        return identityDatabase.deleteIdentity(id: identity.id)
            .tryMap {
                DeletionEndpoint.oauthRevoke(
                    token: try secretsService.item(.accessToken),
                    clientID: try secretsService.item(.clientID),
                    clientSecret: try secretsService.item(.clientSecret))
            }
            .flatMap(networkClient.request)
            .tryMap { _ in try secretsService.deleteAllItems() }
            .print()
            .eraseToAnyPublisher()
    }

    func updatePushSubscriptions(deviceToken: String) -> AnyPublisher<Void, Error> {
        identityDatabase.identitiesWithOutdatedDeviceTokens(deviceToken: deviceToken)
            .tryMap { [weak self] identities -> [AnyPublisher<Void, Never>] in
                guard let self = self else { return [Empty().eraseToAnyPublisher()] }

                return try identities.map {
                    try self.identityService(id: $0.id)
                        .createPushSubscription(deviceToken: deviceToken, alerts: $0.pushSubscriptionAlerts)
                        .catch { _ in Empty() } // don't want to disrupt pipeline, consider future telemetry
                        .eraseToAnyPublisher()
                }
            }
            .map(Publishers.MergeMany.init)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
