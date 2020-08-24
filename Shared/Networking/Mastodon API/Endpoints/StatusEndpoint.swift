// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum StatusEndpoint {
    case status(id: String)
    case favourite(id: String)
    case unfavourite(id: String)
}

extension StatusEndpoint: MastodonEndpoint {
    typealias ResultType = Status

    var context: [String] {
        defaultContext + ["statuses"]
    }

    var pathComponentsInContext: [String] {
        switch self {
        case let .status(id):
            return [id]
        case let .favourite(id):
            return [id, "favourite"]
        case let .unfavourite(id):
            return [id, "unfavourite"]
        }
    }

    var method: HTTPMethod {
        switch self {
        case .status:
            return .get
        case .favourite, .unfavourite:
            return .post
        }
    }
}
