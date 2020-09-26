// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum ResultsEndpoint {
    case search(query: String, resolve: Bool)
}

extension ResultsEndpoint: Endpoint {
    public typealias ResultType = Results

    public var APIVersion: String {
        switch self {
        case .search:
            return "v2"
        }
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .search:
            return ["search"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .search:
            return .get
        }
    }

    public var queryParameters: [String: String]? {
        switch self {
        case let .search(query, resolve):
            var params = ["q": query]

            if resolve {
                params["resolve"] = String(true)
            }

            return params
        }
    }
}
