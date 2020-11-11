// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum IdentityProofsEndpoint {
    case identityProofs(id: Account.Id)
}

extension IdentityProofsEndpoint: Endpoint {
    public typealias ResultType = [IdentityProof]

    public var context: [String] {
        defaultContext + ["accounts"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .identityProofs(id):
            return [id, "identity_proofs"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .identityProofs:
            return .get
        }
    }
}
