// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

extension Dictionary where Key == PickerEmoji.Category, Value == [PickerEmoji] {
    func snapshot() -> NSDiffableDataSourceSnapshot<PickerEmoji.Category, PickerEmoji> {
        var snapshot = NSDiffableDataSourceSnapshot<PickerEmoji.Category, PickerEmoji>()

        snapshot.appendSections(keys.sorted())

        for (key, value) in self {
            snapshot.appendItems(value, toSection: key)
        }

        return snapshot
    }
}

extension PickerEmoji.Category {
    var displayName: String {
        switch self {
        case .frequentlyUsed:
            return NSLocalizedString("emoji.frequently-used", comment: "")
        case .custom:
            return NSLocalizedString("emoji.custom", comment: "")
        case let .customNamed(name):
            return name
        case let .systemGroup(group):
            return NSLocalizedString(group.localizedStringKey, comment: "")
        }
    }
}
