// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Alamofire

enum AppAuthorizationEndpoint {
    case apps(clientName: String, redirectURI: String, scopes: String, website: URL?)
}

extension AppAuthorizationEndpoint: MastodonEndpoint {
    typealias ResultType = AppAuthorization

    var pathComponentsInContext: [String] {
        switch self {
        case .apps: return ["apps"]
        }
    }

    var method: HTTPMethod {
        switch self {
        case .apps: return .post
        }
    }

    var parameters: [String: Any]? {
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
