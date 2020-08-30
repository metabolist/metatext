// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum AccountEndpoint {
    case verifyCredentials
}

extension AccountEndpoint: MastodonEndpoint {
    public typealias ResultType = Account

    public var context: [String] {
        defaultContext + ["accounts"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .verifyCredentials: return ["verify_credentials"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .verifyCredentials: return .get
        }
    }
}
