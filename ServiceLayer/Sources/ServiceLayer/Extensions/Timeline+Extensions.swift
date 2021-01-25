// Copyright © 2020 Metabolist. All rights reserved.

import MastodonAPI

extension Timeline {
    var endpoint: StatusesEndpoint {
        switch self {
        case .home:
            return .timelinesHome
        case .local:
            return .timelinesPublic(local: true)
        case .federated:
            return .timelinesPublic(local: false)
        case let .list(list):
            return .timelinesList(id: list.id)
        case let .tag(tag):
            return .timelinesTag(tag)
        case let .profile(accountId, profileCollection):
            let excludeReplies: Bool
            let onlyMedia: Bool

            switch profileCollection {
            case .statuses:
                excludeReplies = true
                onlyMedia = false
            case .statusesAndReplies:
                excludeReplies = false
                onlyMedia = false
            case .media:
                excludeReplies = true
                onlyMedia = true
            }

            return .accountsStatuses(
                id: accountId,
                excludeReplies: excludeReplies,
                onlyMedia: onlyMedia,
                pinned: false)
        case .favorites:
            return .favourites
        case .bookmarks:
            return .bookmarks
        }
    }
}
