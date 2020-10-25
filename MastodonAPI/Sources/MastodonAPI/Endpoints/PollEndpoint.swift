// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum PollEndpoint {
    case poll(id: Poll.Id)
    case votes(id: Poll.Id, choices: [Int])
}

extension PollEndpoint: Endpoint {
    public typealias ResultType = Poll

    public var context: [String] {
        defaultContext + ["polls"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .poll(id):
            return [id]
        case let .votes(id, _):
            return [id, "votes"]
        }
    }

    public var jsonBody: [String: Any]? {
        switch self {
        case .poll:
            return nil
        case let .votes(_, choices):
            return ["choices": choices]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .poll:
            return .get
        case .votes:
            return .post
        }
    }
}
