// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI
import Secrets

public struct AllIdentitiesService {
    public let identitiesCreated: AnyPublisher<Identity.Id, Never>

    private let environment: AppEnvironment
    private let database: IdentityDatabase
    private let identitiesCreatedSubject = PassthroughSubject<Identity.Id, Never>()

    public init(environment: AppEnvironment) throws {
        self.environment = environment
        self.database =  try environment.fixtureDatabase ?? IdentityDatabase(
            inMemory: environment.inMemoryContent,
            appGroup: AppEnvironment.appGroup,
            keychain: environment.keychain)
        identitiesCreated = identitiesCreatedSubject.eraseToAnyPublisher()
    }
}

public extension AllIdentitiesService {
    enum IdentityCreation {
        case authentication
        case registration(Registration)
        case browsing
    }

    func identityService(id: Identity.Id) throws -> IdentityService {
        try IdentityService(id: id, database: database, environment: environment)
    }

    func immediateMostRecentlyUsedIdentityIdPublisher() -> AnyPublisher<Identity.Id?, Error> {
        database.immediateMostRecentlyUsedIdentityIdPublisher()
    }

    func mostRecentAuthenticatedIdentity() throws -> Identity? {
        try database.mostRecentAuthenticatedIdentity()
    }

    func createIdentity(url: URL, kind: IdentityCreation) -> AnyPublisher<Never, Error> {
        let id = environment.uuid()
        let secrets = Secrets(identityId: id, keychain: environment.keychain)

        do {
            try secrets.setInstanceURL(url)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        let createIdentityPublisher = database.createIdentity(
            id: id,
            url: url,
            authenticated: kind.authenticated,
            pending: kind.pending)
            .ignoreOutput()
            .handleEvents(receiveCompletion: {
                if case .finished = $0 {
                    identitiesCreatedSubject.send(id)
                }
            })
            .eraseToAnyPublisher()

        let authenticationPublisher: AnyPublisher<(AppAuthorization, AccessToken), Error>

        switch kind {
        case .authentication:
            authenticationPublisher = AuthenticationService(url: url, environment: environment)
                .authenticate()
        case let .registration(registration):
            authenticationPublisher = AuthenticationService(url: url, environment: environment)
                .register(registration, id: id)
        case .browsing:
            return createIdentityPublisher
        }

        return authenticationPublisher
            .tryMap {
                try secrets.setClientId($0.clientId)
                try secrets.setClientSecret($0.clientSecret)
                try secrets.setAccessToken($1.accessToken)
            }
            .flatMap { createIdentityPublisher }
            .eraseToAnyPublisher()
    }

    func deleteIdentity(id: Identity.Id) -> AnyPublisher<Never, Error> {
        database.deleteIdentity(id: id)
            .collect()
            .tryMap { _ -> AnyPublisher<Never, Error> in
                try ContentDatabase.delete(id: id, appGroup: AppEnvironment.appGroup)

                let secrets = Secrets(identityId: id, keychain: environment.keychain)

                defer { secrets.deleteAllItems() }

                do {
                    return MastodonAPIClient(
                        session: environment.session,
                        instanceURL: try secrets.getInstanceURL())
                        .request(EmptyEndpoint.oauthRevoke(
                                    token: try secrets.getAccessToken(),
                                    clientId: try secrets.getClientId(),
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
        database.fetchIdentitiesWithOutdatedDeviceTokens(deviceToken: deviceToken)
            .tryMap { identities -> [AnyPublisher<Never, Never>] in
                try identities.map {
                    try IdentityService(id: $0.id, database: database, environment: environment)
                        .createPushSubscription(deviceToken: deviceToken, alerts: $0.pushSubscriptionAlerts)
                        .catch { _ in Empty() } // don't want to disrupt pipeline
                        .eraseToAnyPublisher()
                }
            }
            .map(Publishers.MergeMany.init)
            .flatMap { $0 }
            .ignoreOutput()
            .eraseToAnyPublisher()
    }
}

private extension AllIdentitiesService.IdentityCreation {
    var authenticated: Bool {
        switch self {
        case .authentication, .registration:
            return true
        case .browsing:
            return false
        }
    }

    var pending: Bool {
        switch self {
        case .registration:
            return true
        case .authentication, .browsing:
            return false
        }
    }
}
