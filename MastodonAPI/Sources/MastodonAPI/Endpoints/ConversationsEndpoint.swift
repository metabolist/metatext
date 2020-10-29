// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum ConversationsEndpoint {
    case conversations
}

extension ConversationsEndpoint: Endpoint {
    public typealias ResultType = [Conversation]

    public var pathComponentsInContext: [String] {
        ["conversations"]
    }

    public var method: HTTPMethod { .get }
}
