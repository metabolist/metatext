// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum ListsEndpoint {
    case lists
    case listsWithAccount(id: Account.Id)
}

extension ListsEndpoint: Endpoint {
    public typealias ResultType = [List]

    public var context: [String] {
        switch self {
        case .lists:
            return defaultContext
        case .listsWithAccount:
            return defaultContext + ["accounts"]
        }
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .lists:
            return ["lists"]
        case let .listsWithAccount(id):
            return [id, "lists"]
        }
    }

    public var method: HTTPMethod {
        .get
    }
}
