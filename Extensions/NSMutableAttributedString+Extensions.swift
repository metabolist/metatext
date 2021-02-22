// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import Mastodon
import UIKit
import ViewModels

extension NSMutableAttributedString {
    func insert(emojis: [Emoji], view: UIView & EmojiInsertable, identityContext: IdentityContext) {
        for emoji in emojis {
            let token = ":\(emoji.shortcode):"

            while let tokenRange = string.range(of: token) {
                let attachment = AnimatedTextAttachment()
                let url: URL

                if !identityContext.appPreferences.shouldReduceMotion,
                   identityContext.appPreferences.animateCustomEmojis {
                    url = emoji.url
                } else {
                    url = emoji.staticUrl
                }

                attachment.accessibilityLabel = emoji.shortcode
                attachment.kf.setImage(with: url, attributedView: view)
                replaceCharacters(in: NSRange(tokenRange, in: string), with: NSAttributedString(attachment: attachment))
            }
        }
    }

    func resizeAttachments(toLineHeight lineHeight: CGFloat) {
        enumerateAttribute(.attachment, in: NSRange(location: 0, length: length), options: []) { attribute, _, _ in
            guard let attachment = attribute as? NSTextAttachment else { return }

            attachment.bounds = CGRect(x: 0, y: lineHeight * -0.25, width: lineHeight, height: lineHeight)
        }
    }

    func appendWithSeparator(_ string: NSAttributedString) {
        append(.init(string: .separator))
        append(string)
    }

    func appendWithSeparator(_ string: String) {
        appendWithSeparator(.init(string: string))
    }
}
