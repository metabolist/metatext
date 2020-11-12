// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum RelationshipEndpoint {
    case accountsFollow(id: Account.Id)
    case accountsUnfollow(id: Account.Id)
}

extension RelationshipEndpoint: Endpoint {
    public typealias ResultType = Relationship

    public var context: [String] {
        defaultContext + ["accounts"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .accountsFollow(id):
            return [id, "follow"]
        case let .accountsUnfollow(id):
            return [id, "unfollow"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .accountsFollow, .accountsUnfollow:
            return .post
        }
    }
}
