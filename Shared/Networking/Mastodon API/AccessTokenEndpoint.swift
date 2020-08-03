// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum AccessTokenEndpoint {
    case oauthToken(
        clientID: String,
        clientSecret: String,
        code: String,
        grantType: String,
        scopes: String,
        redirectURI: String
    )
}

extension AccessTokenEndpoint: MastodonEndpoint {
    typealias ResultType = AccessToken

    var context: [String] { [] }

    var pathComponentsInContext: [String] {
        ["oauth", "token"]
    }

    var method: HTTPMethod {
        switch self {
        case .oauthToken: return .post
        }
    }

    var parameters: [String: Any]? {
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
