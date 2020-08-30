// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum PreferencesEndpoint {
    case preferences
}

extension PreferencesEndpoint: MastodonEndpoint {
    public typealias ResultType = MastodonPreferences

    public var pathComponentsInContext: [String] {
        switch self {
        case .preferences: return ["preferences"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .preferences: return .get
        }
    }
}
