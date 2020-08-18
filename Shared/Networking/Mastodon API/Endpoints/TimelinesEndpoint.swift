// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum TimelinesEndpoint {
    case `public`(local: Bool)
    case tag(String)
    case home
    case list(id: String)
}

extension TimelinesEndpoint: MastodonEndpoint {
    typealias ResultType = [Status]

    var context: [String] {
        defaultContext + ["timelines"]
    }

    var pathComponentsInContext: [String] {
        switch self {
        case .public:
            return ["public"]
        case let .tag(tag):
            return ["tag", tag]
        case .home:
            return ["home"]
        case let .list(id):
            return ["list", id]
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case let .public(local):
            return ["local": local]
        default:
            return nil
        }
    }

    var method: HTTPMethod { .get }
}
