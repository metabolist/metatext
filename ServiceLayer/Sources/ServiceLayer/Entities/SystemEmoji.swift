// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct SystemEmoji: Codable, Hashable {
    public let emoji: String
    public let version: Float
    public let skins: Bool
}

public extension SystemEmoji {
    enum Group: Int, Codable, Hashable, CaseIterable {
        case smileysAndEmotion
        case peopleAndBody
        case components
        case animalsAndNature
        case foodAndDrink
        case travelAndPlaces
        case activites
        case objects
        case symbols
        case flags
    }
}

extension SystemEmoji: Comparable {
    public static func < (lhs: SystemEmoji, rhs: SystemEmoji) -> Bool {
        lhs.emoji < rhs.emoji
    }
}
