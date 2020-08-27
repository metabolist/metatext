// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum Timeline {
    case home
    case local
    case federated
    case list(MastodonList)
}

extension Timeline {
    var id: String {
        switch self {
        case .home:
            return "home"
        case .local:
            return "local"
        case .federated:
            return "federated"
        case let .list(list):
            return list.id
        }
    }

    var endpoint: TimelinesEndpoint {
        switch self {
        case .home:
            return .home
        case .local:
            return .public(local: true)
        case .federated:
            return .public(local: false)
        case let .list(list):
            return .list(id: list.id)
        }
    }
}
