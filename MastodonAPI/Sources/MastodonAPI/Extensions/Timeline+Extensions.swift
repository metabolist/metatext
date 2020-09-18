// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public extension Timeline {
    var endpoint: StatusesEndpoint {
        switch self {
        case .home:
            return .timelinesHome
        case .local:
            return .timelinesPublic(local: true)
        case .federated:
            return .timelinesPublic(local: false)
        case let .list(list):
            return .timelinesList(id: list.id)
        case let .tag(tag):
            return .timelinesTag(tag)
        }
    }
}
