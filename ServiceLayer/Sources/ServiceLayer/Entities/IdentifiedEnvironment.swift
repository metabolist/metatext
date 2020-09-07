// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation

public class IdentifiedEnvironment {
    @Published public private(set) var identity: Identity
    public let appEnvironment: AppEnvironment
    public let identityService: IdentityService
    public let observationErrors: AnyPublisher<Error, Never>

    init(id: UUID, database: IdentityDatabase, environment: AppEnvironment) throws {
        appEnvironment = environment

        // The scheduling on the observation is immediate so an initial value can be extracted
        let sharedObservation = database.identityObservation(id: id).share()
        var initialIdentity: Identity?

        _ = sharedObservation.first().sink(
            receiveCompletion: { _ in },
            receiveValue: { initialIdentity = $0 })

        guard let identity = initialIdentity else { throw IdentityDatabaseError.identityNotFound }

        self.identity = identity
        identityService = try IdentityService(id: identity.id,
                                              instanceURL: identity.url,
                                              database: database,
                                              environment: environment)

        let observationErrorsSubject = PassthroughSubject<Error, Never>()

        self.observationErrors = observationErrorsSubject.eraseToAnyPublisher()

        sharedObservation.catch { error -> Empty<Identity, Never> in
            observationErrorsSubject.send(error)

            return Empty()
        }
        .assign(to: &$identity)
    }
}
