// Copyright © 2020 Metabolist. All rights reserved.

public struct CollectionItem: Hashable {
    public let id: String
    public let kind: Kind
}

public extension CollectionItem {
    enum Kind: Hashable, CaseIterable {
        case status
        case account
    }
}
