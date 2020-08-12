// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum PushSubscriptionEndpoint {
    case create(
            endpoint: URL,
            publicKey: String,
            auth: String,
            follow: Bool,
            favourite: Bool,
            reblog: Bool,
            mention: Bool,
            poll: Bool)
    case read
    case update(follow: Bool, favourite: Bool, reblog: Bool, mention: Bool, poll: Bool)
    case delete
}

extension PushSubscriptionEndpoint: MastodonEndpoint {
    typealias ResultType = PushSubscription

    var context: [String] {
        defaultContext + ["push", "subscription"]
    }

    var pathComponentsInContext: [String] { [] }

    var method: HTTPMethod {
        switch self {
        case .create: return .post
        case .read: return .get
        case .update: return .put
        case .delete: return .delete
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case let .create(endpoint, publicKey, auth, follow, favourite, reblog, mention, poll):
            return ["subscription":
                        ["endpoint": endpoint.absoluteString,
                         "keys": [
                            "p256dh": publicKey,
                            "auth": auth]],
                    "data": [
                        "alerts": [
                            "follow": follow,
                            "favourite": favourite,
                            "reblog": reblog,
                            "mention": mention,
                            "poll": poll
                        ]]]
        case let .update(follow, favourite, reblog, mention, poll):
            return ["data":
                        ["alerts":
                            ["follow": follow,
                             "favourite": favourite,
                             "reblog": reblog,
                             "mention": mention,
                             "poll": poll]]]
        default: return nil
        }
    }
}
