// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum TagsEndpoint {
    case trends
}

extension TagsEndpoint: Endpoint {
    public typealias ResultType = [Tag]

    public var pathComponentsInContext: [String] {
        switch self {
        case .trends: return ["trends"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .trends: return .get
        }
    }
}
