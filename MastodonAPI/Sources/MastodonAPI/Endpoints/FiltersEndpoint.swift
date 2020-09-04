// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum FiltersEndpoint {
    case filters
}

extension FiltersEndpoint: Endpoint {
    public typealias ResultType = [Filter]

    public var context: [String] {
        defaultContext + ["filters"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .filters:
            return []
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .filters:
            return .get
        }
    }
}
