// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum AccessTokenEndpoint {
    case oauthToken(
            clientId: String,
            clientSecret: String,
            grantType: String,
            scopes: String,
            code: String?,
            redirectURI: String?
         )
    case accounts(Registration)
}

public extension AccessTokenEndpoint {
    struct Registration {
        public var username = ""
        public var email = ""
        public var password = ""
        public var locale: String
        public var reason = ""
        public var agreement = false

        public init(locale: String) {
            self.locale = locale
        }
    }
}

extension AccessTokenEndpoint: Endpoint {
    public typealias ResultType = AccessToken

    public var context: [String] {
        switch self {
        case .oauthToken:
            return []
        case .accounts:
            return defaultContext
        }
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .oauthToken:
            return ["oauth", "token"]
        case .accounts:
            return ["accounts"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .oauthToken, .accounts: return .post
        }
    }

    public var jsonBody: [String: Any]? {
        switch self {
        case let .oauthToken(clientId, clientSecret, grantType, scopes, code, redirectURI):
            var params = [
                "client_id": clientId,
                "client_secret": clientSecret,
                "grant_type": grantType,
                "scope": scopes]

            params["code"] = code
            params["redirect_uri"] = redirectURI

            return params
        case let .accounts(registration):
            var params: [String: Any] = [
                "username": registration.username,
                "email": registration.email,
                "password": registration.password,
                "locale": registration.locale,
                "agreement": registration.agreement]

            if !registration.reason.isEmpty {
                params["reason"] = registration.reason
            }

            return params
        }
    }
}
