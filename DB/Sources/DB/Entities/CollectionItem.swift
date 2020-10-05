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
        public let isContextParent: Bool
        public let isPinned: Bool
        public let isReplyInContext: Bool
        public let hasReplyFollowing: Bool

        init(status: Status,
             isContextParent: Bool = false,
             isPinned: Bool = false,
             isReplyInContext: Bool = false,
             hasReplyFollowing: Bool = false) {
            self.status = status
            self.isContextParent = isContextParent
            self.isPinned = isPinned
            self.isReplyInContext = isReplyInContext
            self.hasReplyFollowing = hasReplyFollowing
        }
    }
}
