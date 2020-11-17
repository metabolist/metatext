// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum RelationshipEndpoint {
    case accountsFollow(id: Account.Id, showReblogs: Bool? = nil)
    case accountsUnfollow(id: Account.Id)
    case accountsBlock(id: Account.Id)
    case accountsUnblock(id: Account.Id)
    case accountsMute(id: Account.Id)
    case accountsUnmute(id: Account.Id)
    case accountsPin(id: Account.Id)
    case accountsUnpin(id: Account.Id)
    case note(String, id: Account.Id)
}

extension RelationshipEndpoint: Endpoint {
    public typealias ResultType = Relationship

    public var context: [String] {
        defaultContext + ["accounts"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .accountsFollow(id, _):
            return [id, "follow"]
        case let .accountsUnfollow(id):
            return [id, "unfollow"]
        case let .accountsBlock(id):
            return [id, "block"]
        case let .accountsUnblock(id):
            return [id, "unblock"]
        case let .accountsMute(id):
            return [id, "mute"]
        case let .accountsUnmute(id):
            return [id, "unmute"]
        case let .accountsPin(id):
            return [id, "pin"]
        case let .accountsUnpin(id):
            return [id, "unpin"]
        case let .note(_, id):
            return [id, "note"]
        }
    }

    public var queryParameters: [URLQueryItem] {
        switch self {
        case let .accountsFollow(_, showReblogs):
            if let showReblogs = showReblogs {
                return [URLQueryItem(name: "reblogs", value: String(showReblogs))]
            } else {
                return []
            }
        default:
            return []
        }
    }

    public var jsonBody: [String: Any]? {
        switch self {
        case let .note(note, _):
            return ["comment": note]
        default:
            return nil
        }
    }

    public var method: HTTPMethod {
        .post
    }
}
