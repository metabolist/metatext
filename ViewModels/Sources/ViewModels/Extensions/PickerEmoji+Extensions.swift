// Copyright © 2021 Metabolist. All rights reserved.

import Foundation

public extension PickerEmoji {
    func applyingDefaultSkinTone(identityContext: IdentityContext) -> PickerEmoji {
        if case let .system(systemEmoji, infrequentlyUsed) = self,
           let defaultEmojiSkinTone = identityContext.appPreferences.defaultEmojiSkinTone {
            return .system(systemEmoji.applying(skinTone: defaultEmojiSkinTone), infrequentlyUsed: infrequentlyUsed)
        } else {
            return self
        }
    }
}
