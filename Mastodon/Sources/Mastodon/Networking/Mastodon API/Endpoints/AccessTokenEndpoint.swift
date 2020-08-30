// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum AccessTokenEndpoint {
    case oauthToken(
        clientID: String,
        clientSecret: String,
        code: String,
        grantType: String,
        scopes: String,
        redirectURI: String
    )
}

extension AccessTokenEndpoint: Endpoint {
    public typealias ResultType = AccessToken

    public var context: [String] { [] }

    public var pathComponentsInContext: [String] {
        ["oauth", "token"]
    }

    public var method: HTTPMethod {
        switch self {
        case .oauthToken: return .post
        }
    }

    public var parameters: [String: Any]? {
        switch self {
        case let .oauthToken(clientID, clientSecret, code, grantType, scopes, redirectURI):
            return [
                "client_id": clientID,
                "client_secret": clientSecret,
                "code": code,
                "grant_type": grantType,
                "scope": scopes,
                "redirect_uri": redirectURI
            ]
        }
    }
}
