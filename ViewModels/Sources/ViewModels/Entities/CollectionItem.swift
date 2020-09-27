// Copyright © 2020 Metabolist. All rights reserved.

public struct CollectionItem: Hashable {
    public let id: String
    public let kind: Kind
    public let info: [InfoKey: AnyHashable]

    init(id: String, kind: Kind, info: [InfoKey: AnyHashable]? = nil) {
        self.id = id
        self.kind = kind
        self.info = info ?? [InfoKey: AnyHashable]()
    }
}

public extension CollectionItem {
    enum Kind: Hashable, CaseIterable {
        case status
        case account
    }

    enum InfoKey {
        case pinned
    }
}
