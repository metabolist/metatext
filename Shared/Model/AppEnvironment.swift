// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

struct AppEnvironment {
    let URLSessionConfiguration: URLSessionConfiguration
    let identityDatabase: IdentityDatabase
    let defaults: Defaults
    let secrets: Secrets
    let webAuthSessionType: WebAuthSession.Type
}

class IdentifiedEnvironment {
    @Published var identity: Identity
    let observationErrors: AnyPublisher<Error, Never>
    let networkClient: MastodonClient
    let appEnvironment: AppEnvironment

    private var cancellables = Set<AnyCancellable>()
    private let observationErrorsInput = PassthroughSubject<Error, Never>()

    init(identityID: String, appEnvironment: AppEnvironment) throws {
        self.appEnvironment = appEnvironment
        observationErrors = observationErrorsInput.eraseToAnyPublisher()
        networkClient = MastodonClient(configuration: appEnvironment.URLSessionConfiguration)
        networkClient.accessToken = try appEnvironment.secrets.item(.accessToken, forIdentityID: identityID)

        let observation = appEnvironment.identityDatabase.identityObservation(id: identityID).share()

        var initialIdentity: Identity?

        observation.first().sink(
            receiveCompletion: { _ in },
            receiveValue: { initialIdentity = $0 })
            .store(in: &cancellables)

        guard let identity = initialIdentity else { throw IdentityDatabaseError.identityNotFound }

        self.identity = identity
        networkClient.instanceURL = identity.url

        observation.catch { [weak self] error -> Empty<Identity, Never> in
            self?.observationErrorsInput.send(error)

            return Empty()
        }
        .assign(to: &$identity)
    }
}
