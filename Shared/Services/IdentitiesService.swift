// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class IdentitiesService {
    @Published var mostRecentlyUsedIdentityID: UUID?

    private let identityDatabase: IdentityDatabase
    private let keychainService: KeychainServiceType
    private let environment: AppEnvironment

    init(identityDatabase: IdentityDatabase, keychainService: KeychainServiceType, environment: AppEnvironment) {
        self.identityDatabase = identityDatabase
        self.keychainService = keychainService
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
                            keychainService: keychainService,
                            environment: environment)
    }

    func createIdentity(id: UUID, instanceURL: URL) -> AnyPublisher<Void, Error> {
        identityDatabase.createIdentity(id: id, url: instanceURL)
    }

    func authorizeIdentity(id: UUID, instanceURL: URL) -> AnyPublisher<Void, Error> {
        let secretsService = SecretsService(identityID: id, keychainService: keychainService)
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

    func deleteIdentity(id: UUID) -> AnyPublisher<Void, Error> {
        identityDatabase.deleteIdentity(id: id)
            .continuingIfWeakReferenceIsStillAlive(to: self)
            .tryMap { _, welf -> Void in
                try SecretsService(
                    identityID: id,
                    keychainService: welf.keychainService)
                    .deleteAllItems()

                return ()
            }
            .eraseToAnyPublisher()
    }
}
