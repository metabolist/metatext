// Copyright © 2021 Metabolist. All rights reserved.

import Foundation

public extension PickerEmoji {
    func applyingDefaultSkinTone(identityContext: IdentityContext) -> PickerEmoji {
        if case let .system(systemEmoji, inFrequentlyUsed) = self,
           let defaultEmojiSkinTone = identityContext.appPreferences.defaultEmojiSkinTone {
            return .system(systemEmoji.applying(skinTone: defaultEmojiSkinTone), inFrequentlyUsed: inFrequentlyUsed)
        } else {
            return self
        }
    }
}
