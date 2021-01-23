// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

extension CollectionSection {
    struct Identifier: Hashable {
        let index: Int
        let titleLocalizedStringKey: String?
    }
}

extension Array where Element == CollectionSection {
    func snapshot() -> NSDiffableDataSourceSnapshot<CollectionSection.Identifier, CollectionItem> {
        var snapshot = NSDiffableDataSourceSnapshot<CollectionSection.Identifier, CollectionItem>()

        for (index, section) in enumerated() {
            let identifier = CollectionSection.Identifier(
                index: index,
                titleLocalizedStringKey: section.titleLocalizedStringKey)
            snapshot.appendSections([identifier])
            snapshot.appendItems(section.items, toSection: identifier)
        }

        return snapshot
    }
}
