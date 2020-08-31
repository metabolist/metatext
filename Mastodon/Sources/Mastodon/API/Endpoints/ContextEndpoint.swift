// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP

public enum ContextEndpoint {
    case context(id: String)
}

extension ContextEndpoint: Endpoint {
    public typealias ResultType = Context

    public var context: [String] {
        defaultContext + ["statuses"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .context(id):
            return [id, "context"]
        }
    }

    public var method: HTTPMethod { .get }
}
