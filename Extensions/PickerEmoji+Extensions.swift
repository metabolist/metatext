// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

extension PickerEmoji {
    func applyingDefaultSkinTone(identityContext: IdentityContext) -> PickerEmoji {
        if case let .system(systemEmoji, inFrequentlyUsed) = self,
           let defaultEmojiSkinTone = identityContext.appPreferences.defaultEmojiSkinTone {
            return .system(systemEmoji.applying(skinTone: defaultEmojiSkinTone), inFrequentlyUsed: inFrequentlyUsed)
        } else {
            return self
        }
    }
}

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
