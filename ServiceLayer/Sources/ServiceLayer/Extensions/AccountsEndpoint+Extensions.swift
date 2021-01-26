// Copyright © 2021 Metabolist. All rights reserved.

import MastodonAPI

extension AccountsEndpoint {
    var configuration: CollectionItem.AccountConfiguration {
        switch self {
        case .followRequests:
            return .followRequest
        default:
            return .withNote
        }
    }
}
