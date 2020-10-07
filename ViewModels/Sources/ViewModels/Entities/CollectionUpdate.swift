// Copyright © 2020 Metabolist. All rights reserved.

public struct CollectionUpdate: Hashable {
    public let items: [[CollectionItemIdentifier]]
    public let maintainScrollPosition: CollectionItemIdentifier?
}
