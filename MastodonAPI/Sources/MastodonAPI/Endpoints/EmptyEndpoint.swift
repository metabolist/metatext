// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum EmptyEndpoint {
    case oauthRevoke(token: String, clientId: String, clientSecret: String)
    case deleteList(id: List.Id)
    case deleteFilter(id: Filter.Id)
}

extension EmptyEndpoint: Endpoint {
    public typealias ResultType = [String: String]

    public var context: [String] {
        switch self {
        case .oauthRevoke:
            return ["oauth"]
        case .deleteList:
            return defaultContext + ["lists"]
        case .deleteFilter:
            return defaultContext + ["filters"]
        }
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .oauthRevoke:
            return ["revoke"]
        case let .deleteList(id), let .deleteFilter(id):
            return [id]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .oauthRevoke:
            return .post
        case .deleteList, .deleteFilter:
            return .delete
        }
    }

    public var jsonBody: [String: Any]? {
        switch self {
        case let .oauthRevoke(token, clientId, clientSecret):
            return ["token": token, "client_id": clientId, "client_secret": clientSecret]
        case .deleteList, .deleteFilter:
            return nil
        }
    }
}
