// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum AccountsEndpoint {
    case statusFavouritedBy(id: String)
}

extension AccountsEndpoint: Endpoint {
    public typealias ResultType = [Account]

    public var context: [String] {
        switch self {
        case .statusFavouritedBy:
            return defaultContext + ["statuses"]
        }
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .statusFavouritedBy(id):
            return [id, "favourited_by"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .statusFavouritedBy:
            return .get
        }
    }
}
