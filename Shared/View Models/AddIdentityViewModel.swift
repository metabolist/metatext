// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import AuthenticationServices

class AddIdentityViewModel: ObservableObject {
    @Published var urlFieldText = ""
    @Published var alertItem: AlertItem?
    @Published private(set) var loading = false
    @Published private(set) var addedIdentityID: String?

    private let networkClient: HTTPClient
    private let identityDatabase: IdentityDatabase
    private let secrets: Secrets
    private let webAuthenticationSessionType: WebAuthenticationSessionType.Type
    private let webAuthenticationSessionContextProvider = WebAuthenticationSessionContextProvider()

    init(
        networkClient: HTTPClient,
        identityDatabase: IdentityDatabase,
        secrets: Secrets,
        webAuthenticationSessionType: WebAuthenticationSessionType.Type = ASWebAuthenticationSession.self) {
        self.networkClient = networkClient
        self.identityDatabase = identityDatabase
        self.secrets = secrets
        self.webAuthenticationSessionType = webAuthenticationSessionType
    }

    func goTapped() {
        let identityID = UUID().uuidString
        let instanceURL: URL
        let redirectURL: URL

        do {
            instanceURL = try urlFieldText.url()
            redirectURL = try identityID.url(scheme: MastodonAPI.OAuth.callbackURLScheme)
        } catch {
            alertItem = AlertItem(error: error)

            return
        }

        authorizeApp(
            identityID: identityID,
            instanceURL: instanceURL,
            redirectURL: redirectURL,
            secrets: secrets)
            .authenticationURL(instanceURL: instanceURL, redirectURL: redirectURL)
            .authenticate(
                webAuthenticationSessionType: webAuthenticationSessionType,
                contextProvider: webAuthenticationSessionContextProvider,
                callbackURLScheme: MastodonAPI.OAuth.callbackURLScheme)
            .extractCode()
            .requestAccessToken(
                networkClient: networkClient,
                identityID: identityID,
                instanceURL: instanceURL)
            .createIdentity(
                id: identityID,
                instanceURL: instanceURL,
                identityDatabase: identityDatabase,
                secrets: secrets)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .receive(on: RunLoop.main)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.loading = true },
                receiveCompletion: { [weak self] _ in self?.loading = false  })
            .map { $0 as String? }
            .assign(to: &$addedIdentityID)
    }
}

private extension AddIdentityViewModel {
    private class WebAuthenticationSessionContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            ASPresentationAnchor()
        }
    }

    private func authorizeApp(
        identityID: String,
        instanceURL: URL,
        redirectURL: URL,
        secrets: Secrets) -> AnyPublisher<AppAuthorization, Error> {
        let endpoint = AppAuthorizationEndpoint.apps(
            clientName: MastodonAPI.OAuth.clientName,
            redirectURI: redirectURL.absoluteString,
            scopes: MastodonAPI.OAuth.scopes,
            website: nil)
        let target = MastodonTarget(baseURL: instanceURL, endpoint: endpoint, accessToken: nil)

        return networkClient.request(target)
            .tryMap {
                try secrets.set($0.clientId, forItem: .clientID, forIdentityID: identityID)
                try secrets.set($0.clientSecret, forItem: .clientSecret, forIdentityID: identityID)

                return $0
            }
            .eraseToAnyPublisher()
    }
}

private extension Publisher where Output == AppAuthorization {
    func authenticationURL(
        instanceURL: URL,
        redirectURL: URL) -> AnyPublisher<(AppAuthorization, URL), Error> {
        tryMap { appAuthorization in
            guard var authorizationURLComponents = URLComponents(url: instanceURL, resolvingAgainstBaseURL: true) else {
                throw URLError(.badURL)
            }

            authorizationURLComponents.path = "/oauth/authorize"
            authorizationURLComponents.queryItems = [
                "client_id": appAuthorization.clientId,
                "scope": MastodonAPI.OAuth.scopes,
                "response_type": "code",
                "redirect_uri": redirectURL.absoluteString
            ].map { URLQueryItem(name: $0, value: $1) }

            guard let authorizationURL = authorizationURLComponents.url else {
                throw URLError(.badURL)
            }

            return (appAuthorization, authorizationURL)
        }
        .mapError { $0 as Error }
        .eraseToAnyPublisher()
    }
}

private extension Publisher where Output == (AppAuthorization, URL), Failure == Error {
    func authenticate(
        webAuthenticationSessionType: WebAuthenticationSessionType.Type,
        contextProvider: ASWebAuthenticationPresentationContextProviding,
        callbackURLScheme: String) -> AnyPublisher<(AppAuthorization, URL), Error> {
        flatMap { appAuthorization, url in
            webAuthenticationSessionType.publisher(
                url: url,
                callbackURLScheme: callbackURLScheme,
                presentationContextProvider: contextProvider)
                .tryCatch { error -> AnyPublisher<URL?, Error> in
                    if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                        return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
                    }

                    throw error
                }
                .compactMap { $0 }
                .map { (appAuthorization, $0) }
        }
        .eraseToAnyPublisher()
    }
}

private extension Publisher where Output == (AppAuthorization, URL) {
    // swiftlint:disable large_tuple
    func extractCode() -> AnyPublisher<(AppAuthorization, URL, String), Error> {
        tryMap { appAuthorization, url -> (AppAuthorization, URL, String) in
            guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems,
                  let code = queryItems.first(where: { $0.name == MastodonAPI.OAuth.codeCallbackQueryItemName })?.value
            else { throw MastodonAPI.OAuthError.codeNotFound }

            return (appAuthorization, url, code)
        }
        .eraseToAnyPublisher()
    }
    // swiftlint:enable large_tuple
}

private extension Publisher where Output == (AppAuthorization, URL, String), Failure == Error {
    func requestAccessToken(
        networkClient: HTTPClient,
        identityID: String,
        instanceURL: URL) -> AnyPublisher<AccessToken, Error> {
        flatMap { appAuthorization, url, code -> AnyPublisher<AccessToken, Error> in
            let endpoint = AccessTokenEndpoint.oauthToken(
                clientID: appAuthorization.clientId,
                clientSecret: appAuthorization.clientSecret,
                code: code,
                grantType: MastodonAPI.OAuth.grantType,
                scopes: MastodonAPI.OAuth.scopes,
                redirectURI: url.absoluteString)
            let target = MastodonTarget(baseURL: instanceURL, endpoint: endpoint, accessToken: nil)

            return networkClient.request(target)
        }
        .eraseToAnyPublisher()
    }
}

private extension Publisher where Output == AccessToken {
    func createIdentity(
        id: String,
        instanceURL: URL,
        identityDatabase: IdentityDatabase,
        secrets: Secrets) -> AnyPublisher<String, Error> {
        tryMap { accessToken -> (String, URL) in
            try secrets.set(accessToken.accessToken, forItem: .accessToken, forIdentityID: id)

            return (id, instanceURL)
        }
        .flatMap(identityDatabase.createIdentity)
        .map { id }
        .eraseToAnyPublisher()
    }
}
