// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class AddIdentityViewModel: ObservableObject {
    @Published var urlFieldText = ""
    @Published var alertItem: AlertItem?
    @Published private(set) var loading = false
    let addedIdentityID: AnyPublisher<String, Never>

    private let environment: AppEnvironment
    private let networkClient: MastodonClient
    private let webAuthSessionContextProvider = WebAuthSessionContextProvider()
    private let addedIdentityIDInput = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(environment: AppEnvironment) {
        self.environment = environment
        self.networkClient = MastodonClient(configuration: environment.URLSessionConfiguration)
        addedIdentityID = addedIdentityIDInput.eraseToAnyPublisher()
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
            secrets: environment.secrets)
            .authenticationURL(instanceURL: instanceURL, redirectURL: redirectURL)
            .authenticate(
                webAuthSessionType: environment.webAuthSessionType,
                contextProvider: webAuthSessionContextProvider,
                callbackURLScheme: MastodonAPI.OAuth.callbackURLScheme)
            .extractCode()
            .requestAccessToken(
                networkClient: networkClient,
                identityID: identityID,
                instanceURL: instanceURL,
                redirectURL: redirectURL)
            .createIdentity(id: identityID, instanceURL: instanceURL, environment: environment)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .receive(on: RunLoop.main)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.loading = true },
                receiveCompletion: { [weak self] _ in self?.loading = false  })
            .sink(receiveValue: addedIdentityIDInput.send)
            .store(in: &cancellables)
    }
}

private extension AddIdentityViewModel {
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
    func authenticationURL(instanceURL: URL, redirectURL: URL) -> AnyPublisher<(AppAuthorization, URL), Error> {
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
        webAuthSessionType: WebAuthSession.Type,
        contextProvider: WebAuthSessionContextProvider,
        callbackURLScheme: String) -> AnyPublisher<(AppAuthorization, URL), Error> {
        flatMap { appAuthorization, url in
            webAuthSessionType.publisher(
                url: url,
                callbackURLScheme: callbackURLScheme,
                presentationContextProvider: contextProvider)
                .tryCatch { error -> AnyPublisher<URL?, Error> in
                    if (error as? WebAuthSessionError)?.code == .canceledLogin {
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
    func extractCode() -> AnyPublisher<(AppAuthorization, String), Error> {
        tryMap { appAuthorization, url -> (AppAuthorization, String) in
            guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems,
                  let code = queryItems.first(where: { $0.name == MastodonAPI.OAuth.codeCallbackQueryItemName })?.value
            else { throw MastodonAPI.OAuthError.codeNotFound }

            return (appAuthorization, code)
        }
        .eraseToAnyPublisher()
    }
}

private extension Publisher where Output == (AppAuthorization, String), Failure == Error {
    func requestAccessToken(
        networkClient: HTTPClient,
        identityID: String,
        instanceURL: URL,
        redirectURL: URL) -> AnyPublisher<AccessToken, Error> {
        flatMap { appAuthorization, code -> AnyPublisher<AccessToken, Error> in
            let endpoint = AccessTokenEndpoint.oauthToken(
                clientID: appAuthorization.clientId,
                clientSecret: appAuthorization.clientSecret,
                code: code,
                grantType: MastodonAPI.OAuth.grantType,
                scopes: MastodonAPI.OAuth.scopes,
                redirectURI: redirectURL.absoluteString)
            let target = MastodonTarget(baseURL: instanceURL, endpoint: endpoint, accessToken: nil)

            return networkClient.request(target)
        }
        .eraseToAnyPublisher()
    }
}

private extension Publisher where Output == AccessToken {
    func createIdentity(id: String, instanceURL: URL, environment: AppEnvironment) -> AnyPublisher<String, Error> {
        tryMap { accessToken -> (String, URL) in
            try environment.secrets.set(accessToken.accessToken, forItem: .accessToken, forIdentityID: id)

            return (id, instanceURL)
        }
        .flatMap(environment.identityDatabase.createIdentity)
        .map {
            environment.preferences[.recentIdentityID] = id

            return id
        }
        .eraseToAnyPublisher()
    }
}
