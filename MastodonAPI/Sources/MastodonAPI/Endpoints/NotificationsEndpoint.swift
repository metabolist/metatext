// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum NotificationsEndpoint {
    case notifications
}

extension NotificationsEndpoint: Endpoint {
    public typealias ResultType = [MastodonNotification]

    public var pathComponentsInContext: [String] {
        ["notifications"]
    }

    public var method: HTTPMethod {
        switch self {
        case .notifications:
            return .get
        }
    }
}
