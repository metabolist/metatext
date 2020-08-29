// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum ListEndpoint {
    case create(title: String)
}

extension ListEndpoint: MastodonEndpoint {
    typealias ResultType = MastodonList

    var context: [String] {
        defaultContext + ["lists"]
    }

    var pathComponentsInContext: [String] {
        switch self {
        case .create:
            return []
        }
    }

    var parameters: [String : Any]? {
        switch self {
        case let .create(title):
            return ["title": title]
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create:
            return .post
        }
    }
}
