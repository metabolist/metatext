// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum AnnouncementsEndpoint {
    case announcements
}

extension AnnouncementsEndpoint: Endpoint {
    public typealias ResultType = [Announcement]

    public var pathComponentsInContext: [String] {
        ["announcements"]
    }

    public var method: HTTPMethod {
        .get
    }
}
