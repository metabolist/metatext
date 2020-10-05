// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon

public enum CollectionItem: Hashable {
    case status(StatusConfiguration)
    case loadMore(LoadMore)
    case account(Account)
}

public extension CollectionItem {
    struct StatusConfiguration: Hashable {
        public let status: Status
        public let pinned: Bool
        public let isReplyInContext: Bool
        public let hasReplyFollowing: Bool

        init(status: Status, pinned: Bool = false, isReplyInContext: Bool = false, hasReplyFollowing: Bool = false) {
            self.status = status
            self.pinned = pinned
            self.isReplyInContext = isReplyInContext
            self.hasReplyFollowing = hasReplyFollowing
        }
    }
}
