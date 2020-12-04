// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum StringsEndpoint {
    case domainBlocks
}

extension StringsEndpoint: Endpoint {
    public typealias ResultType = [String]

    public var pathComponentsInContext: [String] {
        switch self {
        case .domainBlocks:
            return ["domain_blocks"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .domainBlocks:
            return .get
        }
    }
}
