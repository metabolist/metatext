// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum ListEndpoint {
    case create(title: String)
}

extension ListEndpoint: Endpoint {
    public typealias ResultType = List

    public var context: [String] {
        defaultContext + ["lists"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .create:
            return []
        }
    }

    public var jsonBody: [String: Any]? {
        switch self {
        case let .create(title):
            return ["title": title]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .create:
            return .post
        }
    }
}
