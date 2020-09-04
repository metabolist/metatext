// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum PreferencesEndpoint {
    case preferences
}

extension PreferencesEndpoint: Endpoint {
    public typealias ResultType = Preferences

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
