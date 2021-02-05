// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum NotificationEndpoint {
    case notification(id: MastodonNotification.Id)
}

extension NotificationEndpoint: Endpoint {
    public typealias ResultType = MastodonNotification

    public var context: [String] {
        defaultContext + ["notifications"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .notification(id):
            return [id]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .notification:
            return .get
        }
    }
}
