// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import ServiceLayer

public struct CollectionItemIdentifier: Hashable {
    public let id: String
    public let kind: Kind
    public let info: [InfoKey: AnyHashable]
}

public extension CollectionItemIdentifier {
    enum Kind: Hashable, CaseIterable {
        case status
        case loadMore
        case account
    }

    enum InfoKey {
        case pinned
    }
}

extension CollectionItemIdentifier {
    init(item: CollectionItem) {
        switch item {
        case let .status(configuration):
            id = configuration.status.id
            kind = .status
            info = configuration.isPinned ? [.pinned: true] : [:]
        case let .loadMore(loadMore):
            id = loadMore.afterStatusId
            kind = .loadMore
            info = [:]
        case let .account(account):
            id = account.id
            kind = .account
            info = [:]
        }
    }
}
