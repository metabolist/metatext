// Copyright © 2021 Metabolist. All rights reserved.

import Foundation

public struct CollectionSection: Hashable {
    public let items: [CollectionItem]
    public let searchScope: SearchScope?

    public init(items: [CollectionItem], searchScope: SearchScope? = nil) {
        self.items = items
        self.searchScope = searchScope
    }
}
