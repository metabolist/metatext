// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum EmojisEndpoint {
    case customEmojis
}

extension EmojisEndpoint: Endpoint {
    public typealias ResultType = [Emoji]

    public var pathComponentsInContext: [String] {
        ["custom_emojis"]
    }

    public var method: HTTPMethod {
        .get
    }
}
