// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum DeletionEndpoint {
    case oauthRevoke(token: String, clientID: String, clientSecret: String)
}

extension DeletionEndpoint: MastodonEndpoint {
    typealias ResultType = [String: String]

    var context: [String] {
        switch self {
        case .oauthRevoke:
            return []
        }
    }

    var pathComponentsInContext: [String] {
        switch self {
        case .oauthRevoke:
            return ["oauth", "revoke"]
        }
    }

    var method: HTTPMethod {
        switch self {
        case .oauthRevoke:
            return .post
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case let .oauthRevoke(token, clientID, clientSecret):
            return ["token": token, "client_id": clientID, "client_secret": clientSecret]
        }
    }
}
