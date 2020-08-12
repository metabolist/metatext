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
        let secretsService = SecretsService(identityID: id, keychainServiceType: environment.keychainServiceType)
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
        let environment = self.environment

        return identityDatabase.deleteIdentity(id: id)
            .tryMap { _ -> Void in
                try SecretsService(
                    identityID: id,
                    keychainServiceType: environment.keychainServiceType)
                    .deleteAllItems()

                return ()
            }
            .eraseToAnyPublisher()
    }

    func updatePushSubscription(
        identityID: UUID,
        instanceURL: URL,
        deviceToken: String,
        alerts: PushSubscription.Alerts?) -> AnyPublisher<Void, Error> {
        let secretsService = SecretsService(
            identityID: identityID,
            keychainServiceType: environment.keychainServiceType)
        let accessTokenOptional: String?

        do {
            accessTokenOptional = try secretsService.item(.accessToken) as String?
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        guard let accessToken: String = accessTokenOptional
        else { return Empty().eraseToAnyPublisher() }

        let publicKey: String
        let auth: String

        do {
            publicKey = try secretsService.generatePushKeyAndReturnPublicKey().base64EncodedString()
            auth = try secretsService.generatePushAuth().base64EncodedString()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        let networkClient = MastodonClient(session: environment.session)
        networkClient.instanceURL = instanceURL
        networkClient.accessToken = accessToken

        let endpoint = Self.pushSubscriptionEndpointURL
            .appendingPathComponent(deviceToken)
            .appendingPathComponent(identityID.uuidString)

        return networkClient.request(
            PushSubscriptionEndpoint.create(
                endpoint: endpoint,
                publicKey: publicKey,
                auth: auth,
                follow: alerts?.follow ?? true,
                favourite: alerts?.favourite ?? true,
                reblog: alerts?.reblog ?? true,
                mention: alerts?.mention ?? true,
                poll: alerts?.poll ?? true))
            .map { (deviceToken, $0.alerts, identityID) }
            .flatMap(identityDatabase.updatePushSubscription(deviceToken:alerts:forIdentityID:))
            .eraseToAnyPublisher()
    }

    func updatePushSubscriptions(deviceToken: String) -> AnyPublisher<Void, Error> {
        identityDatabase.identitiesWithOutdatedDeviceTokens(deviceToken: deviceToken)
            .flatMap { identities -> Publishers.MergeMany<AnyPublisher<Void, Never>> in
                Publishers.MergeMany(
                    identities.map { [weak self] in
                        guard let self = self else { return Empty().eraseToAnyPublisher() }

                        return self.updatePushSubscription(
                            identityID: $0.id,
                            instanceURL: $0.url,
                            deviceToken: deviceToken,
                            alerts: $0.pushSubscriptionAlerts)
                            .catch { _ in Empty() } // can't let one failure stop the pipeline
                            .eraseToAnyPublisher()
                    })
            }
            .eraseToAnyPublisher()
    }
}

private extension IdentitiesService {
    #if DEBUG
    static let pushSubscriptionEndpointURL = URL(string: "https://metatext-apns.metabolist.com/push?sandbox=true")!
    #else
    static let pushSubscriptionEndpointURL = URL(string: "https://metatext-apns.metabolist.com/push")!
    #endif
}
