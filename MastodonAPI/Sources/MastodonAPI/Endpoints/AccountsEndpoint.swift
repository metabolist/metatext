// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum AccountsEndpoint {
    case rebloggedBy(id: Status.Id)
    case favouritedBy(id: Status.Id)
}

extension AccountsEndpoint: Endpoint {
    public typealias ResultType = [Account]

    public var context: [String] {
        switch self {
        case .rebloggedBy, .favouritedBy:
            return defaultContext + ["statuses"]
        }
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .rebloggedBy(id):
            return [id, "reblogged_by"]
        case let .favouritedBy(id):
            return [id, "favourited_by"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .rebloggedBy, .favouritedBy:
            return .get
        }
    }
}
