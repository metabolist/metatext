// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class IdentitiesService {
    @Published var mostRecentlyUsedIdentityID: UUID?

    private let environment: AppEnvironment
    private var cancellables = Set<AnyCancellable>()

    init(environment: AppEnvironment) {
        self.environment = environment

        environment.identityDatabase.mostRecentlyUsedIdentityIDObservation()
            .replaceError(with: nil)
            .assign(to: &$mostRecentlyUsedIdentityID)
    }
}

extension IdentitiesService {
    func identityService(id: UUID) throws -> IdentityService {
        try IdentityService(identityID: id, environment: environment)
    }

    func authenticationService() -> AuthenticationService {
        AuthenticationService(environment: environment)
    }

    func deleteIdentity(id: UUID) -> AnyPublisher<Void, Error> {
        environment.identityDatabase.deleteIdentity(id: id)
            .continuingIfWeakReferenceIsStillAlive(to: self)
            .tryMap { _, welf -> Void in
                try SecretsService(
                    identityID: id,
                    keychainService: welf.environment.keychainService)
                    .deleteAllItems()

                return ()
            }
            .eraseToAnyPublisher()
    }
}
