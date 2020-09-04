// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public extension Timeline {
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
        case let .tag(tag):
            return .tag(tag)
        }
    }
}
