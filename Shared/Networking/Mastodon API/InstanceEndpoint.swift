// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum InstanceEndpoint {
    case instance
}

extension InstanceEndpoint: MastodonEndpoint {
    typealias ResultType = Instance

    var pathComponentsInContext: [String] {
        switch self {
        case .instance: return ["instance"]
        }
    }

    var method: HTTPMethod {
        switch self {
        case .instance: return .get
        }
    }
}
