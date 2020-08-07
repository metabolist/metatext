// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum PreferencesEndpoint {
    case preferences
}

extension PreferencesEndpoint: MastodonEndpoint {
    typealias ResultType = MastodonPreferences

    var pathComponentsInContext: [String] {
        switch self {
        case .preferences: return ["preferences"]
        }
    }

    var method: HTTPMethod {
        switch self {
        case .preferences: return .get
        }
    }
}
