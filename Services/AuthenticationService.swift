// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import Mastodon

struct AuthenticationService {
    private let networkClient: APIClient
    private let webAuthSessionType: WebAuthSession.Type
    private let webAuthSessionContextProvider = WebAuthSessionContextProvider()

    init(environment: AppEnvironment) {
        networkClient = APIClient(session: environment.session)
        webAuthSessionType = environment.webAuthSessionType
    }
}

extension AuthenticationService {
    func authorizeApp(instanceURL: URL) -> AnyPublisher<AppAuthorization, Error> {
        let endpoint = AppAuthorizationEndpoint.apps(
            clientName: OAuth.clientName,
            redirectURI: OAuth.callbackURL.absoluteString,
            scopes: OAuth.scopes,
            website: OAuth.website)
        let target = APITarget(baseURL: instanceURL, endpoint: endpoint, accessToken: nil)

        return networkClient.request(target)
    }

    func authenticate(instanceURL: URL, appAuthorization: AppAuthorization) -> AnyPublisher<AccessToken, Error> {
        guard let authorizationURL = authorizationURL(
                instanceURL: instanceURL,
                clientID: appAuthorization.clientId) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return webAuthSessionType.publisher(
            url: authorizationURL,
            callbackURLScheme: OAuth.callbackURLScheme,
            presentationContextProvider: webAuthSessionContextProvider)
            .tryCatch { error -> AnyPublisher<URL?, Error> in
                if (error as? WebAuthSessionError)?.code == .canceledLogin {
                    return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
                }

                throw error
            }
            .compactMap { $0 }
            .tryMap { url -> String in
                guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems,
                      let code = queryItems.first(where: {
                        $0.name == OAuth.codeCallbackQueryItemName
                      })?.value
                else { throw OAuthError.codeNotFound }

                return code
            }
            .flatMap { code -> AnyPublisher<AccessToken, Error> in
                let endpoint = AccessTokenEndpoint.oauthToken(
                    clientID: appAuthorization.clientId,
                    clientSecret: appAuthorization.clientSecret,
                    code: code,
                    grantType: OAuth.grantType,
                    scopes: OAuth.scopes,
                    redirectURI: OAuth.callbackURL.absoluteString)
                let target = APITarget(baseURL: instanceURL, endpoint: endpoint, accessToken: nil)

                return networkClient.request(target)
            }
            .eraseToAnyPublisher()
    }
}

private extension AuthenticationService {
    struct OAuth {
        static let clientName = "Metatext"
        static let scopes = "read write follow push"
        static let codeCallbackQueryItemName = "code"
        static let grantType = "authorization_code"
        static let callbackURLScheme = "metatext"
        static let callbackURL = URL(string: "\(callbackURLScheme)://oauth.callback")!
        static let website = URL(string: "https://metabolist.com/metatext")!
    }

    enum OAuthError {
        case codeNotFound
    }

    private func authorizationURL(instanceURL: URL, clientID: String) -> URL? {
        guard var authorizationURLComponents = URLComponents(url: instanceURL, resolvingAgainstBaseURL: true) else {
            return nil
        }

        authorizationURLComponents.path = "/oauth/authorize"
        authorizationURLComponents.queryItems = [
            "client_id": clientID,
            "scope": OAuth.scopes,
            "response_type": "code",
            "redirect_uri": OAuth.callbackURL.absoluteString
        ].map { URLQueryItem(name: $0, value: $1) }

        return authorizationURLComponents.url
    }
}

extension AuthenticationService.OAuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .codeNotFound:
            return NSLocalizedString("oauth.error.code-not-found", comment: "")
        }
    }
}
