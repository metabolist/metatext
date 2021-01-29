// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum PushSubscriptionEndpoint {
    case create(
            endpoint: URL,
            publicKey: String,
            auth: String,
            alerts: PushSubscription.Alerts)
    case read
    case update(alerts: PushSubscription.Alerts)
    case delete
}

extension PushSubscriptionEndpoint: Endpoint {
    public typealias ResultType = PushSubscription

    public var context: [String] {
        defaultContext + ["push", "subscription"]
    }

    public var pathComponentsInContext: [String] { [] }

    public var method: HTTPMethod {
        switch self {
        case .create: return .post
        case .read: return .get
        case .update: return .put
        case .delete: return .delete
        }
    }

    public var jsonBody: [String: Any]? {
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
                            "follow_request": alerts.followRequest,
                            "poll": alerts.poll,
                            "status": alerts.status
                        ]]]
        case let .update(alerts):
            return ["data":
                        ["alerts":
                            ["follow": alerts.follow,
                             "favourite": alerts.favourite,
                             "reblog": alerts.reblog,
                             "mention": alerts.mention,
                             "follow_request": alerts.followRequest,
                             "poll": alerts.poll,
                             "status": alerts.status]]]
        default: return nil
        }
    }
}
