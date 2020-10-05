// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum DeletionEndpoint {
    case oauthRevoke(token: String, clientId: String, clientSecret: String)
    case list(id: List.Id)
    case filter(id: Filter.Id)
}

extension DeletionEndpoint: Endpoint {
    public typealias ResultType = [String: String]

    public var context: [String] {
        switch self {
        case .oauthRevoke:
            return ["oauth"]
        case .list:
            return defaultContext + ["lists"]
        case .filter:
            return defaultContext + ["filters"]
        }
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .oauthRevoke:
            return ["revoke"]
        case let .list(id), let .filter(id):
            return [id]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .oauthRevoke:
            return .post
        case .list, .filter:
            return .delete
        }
    }

    public var jsonBody: [String: Any]? {
        switch self {
        case let .oauthRevoke(token, clientId, clientSecret):
            return ["token": token, "client_id": clientId, "client_secret": clientSecret]
        case .list, .filter:
            return nil
        }
    }
}
