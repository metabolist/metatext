// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import MastodonAPI

public enum AuthenticationError: Error {
    case canceled
}

struct AuthenticationService {
    private let mastodonAPIClient: MastodonAPIClient
    private let webAuthSessionType: WebAuthSession.Type
    private let webAuthSessionContextProvider = WebAuthSessionContextProvider()

    init(url: URL, environment: AppEnvironment) {
        mastodonAPIClient = MastodonAPIClient(session: environment.session, instanceURL: url)
        webAuthSessionType = environment.webAuthSessionType
    }
}

extension AuthenticationService {
    func authenticate() -> AnyPublisher<(AppAuthorization, AccessToken), Error> {
        let authorization = appAuthorization(redirectURI: OAuth.authorizationCallbackURL).share()

        return authorization
            .zip(authorization.flatMap(authenticate(appAuthorization:)))
            .eraseToAnyPublisher()
    }

    func register(_ registration: Registration,
                  id: Identity.Id) -> AnyPublisher<(AppAuthorization, AccessToken), Error> {
        let redirectURI = OAuth.registrationCallbackURL.appendingPathComponent(id.uuidString)
        let authorization = appAuthorization(redirectURI: redirectURI)
            .share()

        return authorization.zip(
            authorization.flatMap { appAuthorization -> AnyPublisher<AccessToken, Error> in
                mastodonAPIClient.request(
                    AccessTokenEndpoint.oauthToken(
                        clientId: appAuthorization.clientId,
                        clientSecret: appAuthorization.clientSecret,
                        grantType: OAuth.registrationGrantType,
                        scopes: OAuth.scopes,
                        code: nil,
                        redirectURI: redirectURI.absoluteString))
                    .flatMap { accessToken -> AnyPublisher<AccessToken, Error> in
                        mastodonAPIClient.accessToken = accessToken.accessToken

                        return mastodonAPIClient.request(AccessTokenEndpoint.accounts(registration))
                    }
                    .eraseToAnyPublisher()
            })
            .eraseToAnyPublisher()
    }
}

private extension AuthenticationService {
    struct OAuth {
        static let clientName = "Metatext"
        static let scopes = "read write follow push"
        static let codeCallbackQueryItemName = "code"
        static let authorizationCodeGrantType = "authorization_code"
        static let registrationGrantType = "client_credentials"
        static let callbackURLScheme = "metatext"
        static let authorizationCallbackURL = URL(string: "\(callbackURLScheme)://oauth.callback")!
        static let registrationCallbackURL = URL(string: "https://metatext.link/confirmation")!
        static let website = URL(string: "https://metabolist.org/metatext")!
    }

    enum OAuthError: Error {
        case codeNotFound
    }

    static func extractCode(oauthCallbackURL: URL) throws -> String {
        guard let queryItems = URLComponents(
                url: oauthCallbackURL,
                resolvingAgainstBaseURL: true)?.queryItems,
              let code = queryItems.first(where: {
                $0.name == OAuth.codeCallbackQueryItemName
              })?.value
        else { throw OAuthError.codeNotFound }

        return code
    }

    func appAuthorization(redirectURI: URL) -> AnyPublisher<AppAuthorization, Error> {
        mastodonAPIClient.request(
            AppAuthorizationEndpoint.apps(
                clientName: OAuth.clientName,
                redirectURI: redirectURI.absoluteString,
                scopes: OAuth.scopes,
                website: OAuth.website))
    }

    func authorizationURL(appAuthorization: AppAuthorization) throws -> URL {
        guard var authorizationURLComponents = URLComponents(
                url: mastodonAPIClient.instanceURL,
                resolvingAgainstBaseURL: true)
        else { throw URLError(.badURL) }

        authorizationURLComponents.path = "/oauth/authorize"
        authorizationURLComponents.queryItems = [
            .init(name: "client_id", value: appAuthorization.clientId),
            .init(name: "scope", value: OAuth.scopes),
            .init(name: "response_type", value: "code"),
            .init(name: "redirect_uri", value: OAuth.authorizationCallbackURL.absoluteString)
        ]

        guard let authorizationURL = authorizationURLComponents.url else {
            throw URLError(.badURL)
        }

        return authorizationURL
    }

    func authenticate(appAuthorization: AppAuthorization) -> AnyPublisher<AccessToken, Error> {
        Just(appAuthorization)
            .tryMap(authorizationURL(appAuthorization:))
            .flatMap {
                webAuthSessionType.publisher(
                    url: $0,
                    callbackURLScheme: OAuth.callbackURLScheme,
                    presentationContextProvider: webAuthSessionContextProvider)
            }
            .mapError { error -> Error in
                if (error as? WebAuthSessionError)?.code == .canceledLogin {
                    return AuthenticationError.canceled as Error
                }

                return error
            }
            .tryMap(Self.extractCode(oauthCallbackURL:))
            .flatMap {
                mastodonAPIClient.request(
                    AccessTokenEndpoint.oauthToken(
                        clientId: appAuthorization.clientId,
                        clientSecret: appAuthorization.clientSecret,
                        grantType: OAuth.authorizationCodeGrantType,
                        scopes: OAuth.scopes,
                        code: $0,
                        redirectURI: OAuth.authorizationCallbackURL.absoluteString))
            }
            .eraseToAnyPublisher()
    }
}
