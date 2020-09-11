// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum AccessTokenEndpoint {
    case oauthToken(
            clientID: String,
            clientSecret: String,
            grantType: String,
            scopes: String,
            code: String?,
            redirectURI: String?
         )
    case accounts(username: String, email: String, password: String, reason: String?)
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

    public var parameters: [String: Any]? {
        switch self {
        case let .oauthToken(clientID, clientSecret, grantType, scopes, code, redirectURI):
            var params = [
                "client_id": clientID,
                "client_secret": clientSecret,
                "grant_type": grantType,
                "scope": scopes]

            params["code"] = code
            params["redirect_uri"] = redirectURI

            return params
        case let .accounts(username, email, password, reason):
            var params: [String: Any] = [
                "username": username,
                "email": email,
                "password": password,
                "locale": Locale.autoupdatingCurrent.languageCode ?? "en", // TODO: probably need to map
                "agreement": true]

            params["reason"] = reason

            return params
        }
    }
}
