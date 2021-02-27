// Copyright © 2021 Metabolist. All rights reserved.

import Foundation

public struct EmojiViewModel {
    let identityContext: IdentityContext

    private let emoji: PickerEmoji

    public init(emoji: PickerEmoji, identityContext: IdentityContext) {
        self.emoji = emoji.applyingDefaultSkinTone(identityContext: identityContext)
        self.identityContext = identityContext
    }
}

public extension EmojiViewModel {
    var name: String { emoji.name }

    var system: Bool { emoji.system }

    var url: URL? {
        guard case let .custom(emoji, _) = emoji else { return nil }

        if identityContext.appPreferences.animateCustomEmojis, let urlString = emoji.url {
            return URL(string: urlString)
        } else if let staticURLString = emoji.staticUrl {
            return URL(string: staticURLString)
        }

        return nil
    }
}
