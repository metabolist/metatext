// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

enum IdentificationError: Error {
    case initialIdentityValueAbsent
}

public final class Identification: ObservableObject {
    @Published private(set) var identity: Identity
    let service: IdentityService
    let observationErrors: AnyPublisher<Error, Never>

    init(service: IdentityService) throws {
        self.service = service
        // The scheduling on the observation is immediate so an initial value can be extracted
        let sharedObservation = service.observation().share()
        var initialIdentity: Identity?

        _ = sharedObservation.first().sink(
            receiveCompletion: { _ in },
            receiveValue: { initialIdentity = $0 })

        guard let identity = initialIdentity else { throw IdentificationError.initialIdentityValueAbsent }

        self.identity = identity

        let observationErrorsSubject = PassthroughSubject<Error, Never>()

        observationErrors = observationErrorsSubject.eraseToAnyPublisher()

        sharedObservation.catch { error -> Empty<Identity, Never> in
            observationErrorsSubject.send(error)

            return Empty()
        }
        .assign(to: &$identity)
    }
}
