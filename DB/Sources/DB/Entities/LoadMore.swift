// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

public struct LoadMore: Hashable {
    public let timeline: Timeline
    public let afterStatusId: String
}

public extension LoadMore {
    enum Direction {
        case up
        case down
    }
}
