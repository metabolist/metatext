// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import ServiceLayer

public struct CollectionItemIdentifier: Hashable {
    public let id: String
    public let kind: Kind
    public let pinned: Bool
    public let showMoreToggled: Bool
}

public extension CollectionItemIdentifier {
    enum Kind: Hashable, CaseIterable {
        case status
        case loadMore
        case account
    }
}

extension CollectionItemIdentifier {
    init(item: CollectionItem) {
        switch item {
        case let .status(status, configuration):
            id = status.id
            kind = .status
            pinned = configuration.isPinned
            showMoreToggled = configuration.showMoreToggled
        case let .loadMore(loadMore):
            id = loadMore.afterStatusId
            kind = .loadMore
            pinned = false
            showMoreToggled = false
        case let .account(account):
            id = account.id
            kind = .account
            pinned = false
            showMoreToggled = false
        }
    }

    public static func isSameExceptShowMoreToggled(lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.kind == rhs.kind && lhs.pinned == rhs.pinned
    }
}
