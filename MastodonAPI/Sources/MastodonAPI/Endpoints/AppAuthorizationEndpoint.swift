// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum AppAuthorizationEndpoint {
    case apps(clientName: String, redirectURI: String, scopes: String, website: URL?)
}

extension AppAuthorizationEndpoint: Endpoint {
    public typealias ResultType = AppAuthorization

    public var pathComponentsInContext: [String] {
        switch self {
        case .apps: return ["apps"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .apps: return .post
        }
    }

    public var jsonBody: [String: Any]? {
        switch self {
        case let .apps(clientName, redirectURI, scopes, website):
            var params = [
                "client_name": clientName,
                "redirect_uris": redirectURI,
                "scopes": scopes
            ]

            params["website"] = website?.absoluteString

            return params
        }
    }
}
