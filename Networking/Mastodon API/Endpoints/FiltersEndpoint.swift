// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum FiltersEndpoint {
    case filters
}

extension FiltersEndpoint: MastodonEndpoint {
    typealias ResultType = [Filter]

    var context: [String] {
        defaultContext + ["filters"]
    }

    var pathComponentsInContext: [String] {
        switch self {
        case .filters:
            return []
        }
    }

    var method: HTTPMethod {
        switch self {
        case .filters:
            return .get
        }
    }
}
