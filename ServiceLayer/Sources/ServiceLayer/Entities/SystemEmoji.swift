// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public final class SystemEmoji: Codable {
    enum CodingKeys: String, CodingKey {
        case emoji = "e"
        case version = "v"
        case skinToneVariations = "s"
        case skinTonesPresent = "p"
    }

    public let emoji: String
    public let version: Float
    public let skinToneVariations: [SystemEmoji]
    public let skinTonesPresent: [SkinTone]

    private init(from: SystemEmoji, maxVersionForSkinToneVariations: Float) {
        emoji = from.emoji
        version = from.version
        skinToneVariations = from.skinToneVariations.filter { !($0.version > maxVersionForSkinToneVariations) }
        skinTonesPresent = from.skinTonesPresent
    }
}

public extension SystemEmoji {
    enum Group: Int, Codable, Hashable, CaseIterable {
        case smileysAndEmotion
        case peopleAndBody
        case components
        case animalsAndNature
        case foodAndDrink
        case travelAndPlaces
        case activities
        case objects
        case symbols
        case flags
    }

    enum SkinTone: Int, Codable, Hashable, CaseIterable {
        case light = 1
        case mediumLight = 2
        case medium = 3
        case mediumDark = 4
        case dark = 5
    }

    func withMaxVersionForSkinToneVariations(_ version: Float) -> Self {
        Self(from: self, maxVersionForSkinToneVariations: version)
    }

    func applying(skinTone: SkinTone) -> SystemEmoji {
        skinToneVariations.first { $0.skinTonesPresent.allSatisfy { $0 == skinTone } } ?? self
    }
}

extension SystemEmoji: Hashable {
    public static func == (lhs: SystemEmoji, rhs: SystemEmoji) -> Bool {
        lhs.emoji == rhs.emoji
            && lhs.version == rhs.version
            && lhs.skinToneVariations == rhs.skinToneVariations
            && lhs.skinTonesPresent == rhs.skinTonesPresent
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(emoji)
        hasher.combine(version)
        hasher.combine(skinToneVariations)
        hasher.combine(skinTonesPresent)
    }
}
