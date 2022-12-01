// Copyright © 2021 Metabolist. All rights reserved.

import ViewModels

extension SystemEmoji.SkinTone {
    static let noneExample = "🖐"

    var example: String {
        switch self {
        case .light:
            return "🖐🏻"
        case .mediumLight:
            return "🖐🏼"
        case .medium:
            return "🖐🏽"
        case .mediumDark:
            return "🖐🏾"
        case .dark:
            return "🖐🏿"
        }
    }
}

extension SystemEmoji.Group {
    var localizedStringKey: String {
        switch self {
        case .smileysAndEmotion:
            return "emoji.system-group.smileys-and-emotion"
        case .peopleAndBody:
            return "emoji.system-group.people-and-body"
        case .components:
            return "emoji.system-group.components"
        case .animalsAndNature:
            return "emoji.system-group.animals-and-nature"
        case .foodAndDrink:
            return "emoji.system-group.food-and-drink"
        case .travelAndPlaces:
            return "emoji.system-group.travel-and-places"
        case .activities:
            return "emoji.system-group.activities"
        case .objects:
            return "emoji.system-group.objects"
        case .symbols:
            return "emoji.system-group.symbols"
        case .flags:
            return "emoji.system-group.flags"
        }
    }
}
