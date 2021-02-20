// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum ConversationEndpoint {
    case read(id: Conversation.Id)
}

extension ConversationEndpoint: Endpoint {
    public typealias ResultType = Conversation

    public var context: [String] {
        defaultContext + ["conversations"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .read(id):
            return [id, "read"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .read:
            return .post
        }
    }
}
