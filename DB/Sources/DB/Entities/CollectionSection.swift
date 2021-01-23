// Copyright © 2021 Metabolist. All rights reserved.

import Foundation

public struct CollectionSection: Hashable {
    public let items: [CollectionItem]
    public let titleLocalizedStringKey: String?

    public init(items: [CollectionItem], titleLocalizedStringKey: String? = nil) {
        self.items = items
        self.titleLocalizedStringKey = titleLocalizedStringKey
    }
}
