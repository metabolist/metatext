// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public indirect enum PickerEmoji: Hashable {
    case custom(Emoji, inFrequentlyUsed: Bool)
    case system(SystemEmoji, inFrequentlyUsed: Bool)
}

public extension PickerEmoji {
    enum Category: Hashable {
        case frequentlyUsed
        case custom
        case customNamed(String)
        case systemGroup(SystemEmoji.Group)
    }

    var name: String {
        switch self {
        case let .custom(emoji, _):
            return emoji.shortcode
        case let .system(emoji, _):
            return emoji.emoji
        }
    }

    var system: Bool {
        switch self {
        case .system:
            return true
        default:
            return false
        }
    }

    var escaped: String {
        switch self {
        case let .custom(emoji, _):
            return ":\(emoji.shortcode):"
        case let .system(emoji, _):
            return emoji.emoji
        }
    }

    var inFrequentlyUsed: Self {
        switch self {
        case let .custom(emoji, _):
            return .custom(emoji, inFrequentlyUsed: true)
        case let .system(emoji, _):
            return .system(emoji, inFrequentlyUsed: true)
        }
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
