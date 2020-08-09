// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class IdentityService {
    @Published private(set) var identity: Identity
    let observationErrors: AnyPublisher<Error, Never>

    private let networkClient: MastodonClient
    private let environment: AppEnvironment
    private let observationErrorsInput = PassthroughSubject<Error, Never>()

    init(identityID: UUID, environment: AppEnvironment) throws {
        self.environment = environment
        observationErrors = observationErrorsInput.eraseToAnyPublisher()

        let observation = environment.identityDatabase.identityObservation(id: identityID).share()
        var initialIdentity: Identity?

        _ = observation.first().sink(
            receiveCompletion: { _ in },
            receiveValue: { initialIdentity = $0 })

        guard let identity = initialIdentity else { throw IdentityDatabaseError.identityNotFound }

        self.identity = identity
        networkClient = MastodonClient(configuration: environment.URLSessionConfiguration)
        networkClient.instanceURL = identity.url
        networkClient.accessToken = try SecretsService(
            identityID: identityID,
            keychainService: environment.keychainService)
            .item(.accessToken)

        observation.catch { [weak self] error -> Empty<Identity, Never> in
            self?.observationErrorsInput.send(error)

            return Empty()
        }
        .assign(to: &$identity)
    }
}

extension IdentityService {
    var isAuthorized: Bool { networkClient.accessToken != nil }

    func updateLastUse() -> AnyPublisher<Void, Error> {
        environment.identityDatabase.updateLastUsedAt(identityID: identity.id)
    }

    func verifyCredentials() -> AnyPublisher<Void, Error> {
        networkClient.request(AccountEndpoint.verifyCredentials)
            .continuingIfWeakReferenceIsStillAlive(to: self)
            .map { ($0, $1.identity.id) }
            .flatMap(environment.identityDatabase.updateAccount)
            .eraseToAnyPublisher()
    }

    func refreshServerPreferences() -> AnyPublisher<Void, Error> {
        networkClient.request(PreferencesEndpoint.preferences)
            .continuingIfWeakReferenceIsStillAlive(to: self)
            .map { ($1.identity.preferences.updated(from: $0), $1.identity.id) }
            .flatMap(environment.identityDatabase.updatePreferences)
            .eraseToAnyPublisher()
    }

    func refreshInstance() -> AnyPublisher<Void, Error> {
        networkClient.request(InstanceEndpoint.instance)
            .continuingIfWeakReferenceIsStillAlive(to: self)
            .map { ($0, $1.identity.id) }
            .flatMap(environment.identityDatabase.updateInstance)
            .eraseToAnyPublisher()
    }

    func identitiesObservation() -> AnyPublisher<[Identity], Error> {
        environment.identityDatabase.identitiesObservation()
    }

    func recentIdentitiesObservation() -> AnyPublisher<[Identity], Error> {
        environment.identityDatabase.recentIdentitiesObservation(excluding: identity.id)
    }

    func updatePreferences(_ preferences: Identity.Preferences) -> AnyPublisher<Void, Error> {
        environment.identityDatabase.updatePreferences(preferences, forIdentityID: identity.id)
    }
}
