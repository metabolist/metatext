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
            switch group {
            case .smileysAndEmotion:
                return NSLocalizedString("emoji.system-group.smileys-and-emotion", comment: "")
            case .peopleAndBody:
                return NSLocalizedString("emoji.system-group.people-and-body", comment: "")
            case .components:
                return NSLocalizedString("emoji.system-group.components", comment: "")
            case .animalsAndNature:
                return NSLocalizedString("Animals & Nature", comment: "")
            case .foodAndDrink:
                return NSLocalizedString("emoji.system-group.food-and-drink", comment: "")
            case .travelAndPlaces:
                return NSLocalizedString("emoji.system-group.travel-and-places", comment: "")
            case .activites:
                return NSLocalizedString("emoji.system-group.activites", comment: "")
            case .objects:
                return NSLocalizedString("emoji.system-group.objects", comment: "")
            case .symbols:
                return NSLocalizedString("emoji.system-group.symbols", comment: "")
            case .flags:
                return NSLocalizedString("emoji.system-group.flags", comment: "")
            }
        }
    }
}
