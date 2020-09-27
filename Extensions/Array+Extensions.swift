// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

extension Array where Element: Sequence, Element.Element: Hashable {
    func snapshot() -> NSDiffableDataSourceSnapshot<Int, Element.Element> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Element.Element>()

        let sections = [Int](0..<count)

        snapshot.appendSections(sections)

        for section in sections {
            snapshot.appendItems(self[section].map { $0 }, toSection: section)
        }

        return snapshot
    }
}
