// Copyright © 2021 Metabolist. All rights reserved.

import MastodonAPI

extension AccountsEndpoint {
    var configuration: CollectionItem.AccountConfiguration {
        switch self {
        case .mutes:
            return .mute
        case .blocks:
            return .block
        case .followRequests:
            return .followRequest
        default:
            return .withNote
        }
    }
}
