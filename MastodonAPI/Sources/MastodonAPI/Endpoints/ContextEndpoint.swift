// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum ContextEndpoint {
    case context(id: Status.Id)
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
