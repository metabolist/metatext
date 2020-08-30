// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum StatusEndpoint {
    case status(id: String)
    case favourite(id: String)
    case unfavourite(id: String)
}

extension StatusEndpoint: MastodonEndpoint {
    public typealias ResultType = Status

    public var context: [String] {
        defaultContext + ["statuses"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .status(id):
            return [id]
        case let .favourite(id):
            return [id, "favourite"]
        case let .unfavourite(id):
            return [id, "unfavourite"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .status:
            return .get
        case .favourite, .unfavourite:
            return .post
        }
    }
}
