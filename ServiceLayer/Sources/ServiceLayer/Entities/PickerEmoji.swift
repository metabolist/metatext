// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public enum PickerEmoji: Hashable {
    case custom(Emoji)
    case system(SystemEmoji)
}

public extension PickerEmoji {
    enum Category: Hashable {
        case frequentlyUsed
        case custom
        case customNamed(String)
        case systemGroup(SystemEmoji.Group)
    }
}

extension PickerEmoji.Category: Comparable {
    public static func < (lhs: PickerEmoji.Category, rhs: PickerEmoji.Category) -> Bool {
        lhs.order < rhs.order
    }
}

private extension PickerEmoji.Category {
    var order: String {
        switch self {
        case .frequentlyUsed:
            return "0"
        case .custom:
            return "1"
        case let .customNamed(name):
            return "2.\(name)"
        case let .systemGroup(group):
            return "3.\(group.rawValue)"
        }
    }
}
