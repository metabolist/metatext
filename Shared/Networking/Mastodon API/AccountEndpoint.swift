// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum AccountEndpoint {
    case verifyCredentials
}

extension AccountEndpoint: MastodonEndpoint {
    typealias ResultType = Account

    var context: [String] {
        defaultContext + ["accounts"]
    }

    var pathComponentsInContext: [String] {
        switch self {
        case .verifyCredentials: return ["verify_credentials"]
        }
    }

    var method: HTTPMethod {
        switch self {
        case .verifyCredentials: return .get
        }
    }
}
