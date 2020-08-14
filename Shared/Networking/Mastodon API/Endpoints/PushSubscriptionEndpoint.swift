// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum PushSubscriptionEndpoint {
    case create(
            endpoint: URL,
            publicKey: String,
            auth: String,
            alerts: PushSubscription.Alerts)
    case read
    case update(alerts: PushSubscription.Alerts)
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
        case let .create(endpoint, publicKey, auth, alerts):
            return ["subscription":
                        ["endpoint": endpoint.absoluteString,
                         "keys": [
                            "p256dh": publicKey,
                            "auth": auth]],
                    "data": [
                        "alerts": [
                            "follow": alerts.follow,
                            "favourite": alerts.favourite,
                            "reblog": alerts.reblog,
                            "mention": alerts.mention,
                            "poll": alerts.poll
                        ]]]
        case let .update(alerts):
            return ["data":
                        ["alerts":
                            ["follow": alerts.follow,
                             "favourite": alerts.favourite,
                             "reblog": alerts.reblog,
                             "mention": alerts.mention,
                             "poll": alerts.poll]]]
        default: return nil
        }
    }
}
