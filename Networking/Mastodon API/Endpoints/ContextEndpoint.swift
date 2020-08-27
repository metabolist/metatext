// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum ContextEndpoint {
    case context(id: String)
}

extension ContextEndpoint: MastodonEndpoint {
    typealias ResultType = MastodonContext

    var context: [String] {
        defaultContext + ["statuses"]
    }

    var pathComponentsInContext: [String] {
        switch self {
        case let .context(id):
            return [id, "context"]
        }
    }

    var method: HTTPMethod { .get }
}
