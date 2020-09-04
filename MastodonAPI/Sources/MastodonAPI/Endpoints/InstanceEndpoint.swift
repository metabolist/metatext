// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum InstanceEndpoint {
    case instance
}

extension InstanceEndpoint: Endpoint {
    public typealias ResultType = Instance

    public var pathComponentsInContext: [String] {
        switch self {
        case .instance: return ["instance"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .instance: return .get
        }
    }
}
