// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class IdentityService {
    @Published private(set) var identity: Identity
    let observationErrors: AnyPublisher<Error, Never>

    private let identityDatabase: IdentityDatabase
    private let environment: AppEnvironment
    private let networkClient: MastodonClient
    private let observationErrorsInput = PassthroughSubject<Error, Never>()

    init(identityID: UUID,
         identityDatabase: IdentityDatabase,
         environment: AppEnvironment) throws {
        self.identityDatabase = identityDatabase
        self.environment = environment
        observationErrors = observationErrorsInput.eraseToAnyPublisher()

        let observation = identityDatabase.identityObservation(id: identityID).share()
        var initialIdentity: Identity?

        _ = observation.first().sink(
            receiveCompletion: { _ in },
            receiveValue: { initialIdentity = $0 })

        guard let identity = initialIdentity else { throw IdentityDatabaseError.identityNotFound }

        self.identity = identity
        networkClient = MastodonClient(session: environment.session)
        networkClient.instanceURL = identity.url
        networkClient.accessToken = try SecretsService(
            identityID: identityID,
            keychainServiceType: environment.keychainServiceType)
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
        identityDatabase.updateLastUsedAt(identityID: identity.id)
    }

    func verifyCredentials() -> AnyPublisher<Void, Error> {
        networkClient.request(AccountEndpoint.verifyCredentials)
            .zip(Just(identity.id).first().setFailureType(to: Error.self))
            .flatMap(identityDatabase.updateAccount)
            .eraseToAnyPublisher()
    }

    func refreshServerPreferences() -> AnyPublisher<Void, Error> {
        networkClient.request(PreferencesEndpoint.preferences)
            .zip(Just(self).first().setFailureType(to: Error.self))
            .map { ($1.identity.preferences.updated(from: $0), $1.identity.id) }
            .flatMap(identityDatabase.updatePreferences)
            .eraseToAnyPublisher()
    }

    func refreshInstance() -> AnyPublisher<Void, Error> {
        networkClient.request(InstanceEndpoint.instance)
            .zip(Just(identity.id).first().setFailureType(to: Error.self))
            .flatMap(identityDatabase.updateInstance)
            .eraseToAnyPublisher()
    }

    func identitiesObservation() -> AnyPublisher<[Identity], Error> {
        identityDatabase.identitiesObservation()
    }

    func recentIdentitiesObservation() -> AnyPublisher<[Identity], Error> {
        identityDatabase.recentIdentitiesObservation(excluding: identity.id)
    }

    func updatePreferences(_ preferences: Identity.Preferences) -> AnyPublisher<Void, Error> {
        identityDatabase.updatePreferences(preferences, forIdentityID: identity.id)
    }
}
