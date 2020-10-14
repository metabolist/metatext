// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import ServiceLayer

public struct CollectionItemIdentifier: Hashable {
    private let item: CollectionItem

    init(item: CollectionItem) {
        self.item = item
    }
}

public extension CollectionItemIdentifier {
    enum Kind: Hashable, CaseIterable {
        case status
        case loadMore
        case account
    }

    var kind: Kind {
        switch item {
        case .status:
            return .status
        case .loadMore:
            return .loadMore
        case .account:
            return .account
        }
    }
}
