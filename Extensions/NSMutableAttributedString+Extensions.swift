// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import SDWebImage
import UIKit
import ViewModels

extension NSMutableAttributedString {
    func insert(emojis: [Emoji], view: UIView & EmojiInsertable, identityContext: IdentityContext) {
        for emoji in emojis {
            let token = ":\(emoji.shortcode):"

            while let tokenRange = string.range(of: token) {
                let attachment = AnimatedTextAttachment()
                let imageURL: URL?

                if !identityContext.appPreferences.shouldReduceMotion,
                   identityContext.appPreferences.animateCustomEmojis,
                   let urlString = emoji.url {
                    imageURL = URL(stringEscapingPath: urlString)
                } else if let staticURLString = emoji.staticUrl {
                    imageURL = URL(stringEscapingPath: staticURLString)
                } else {
                    imageURL = nil
                }

                attachment.imageView.sd_setImage(with: imageURL) { image, _, _, _ in
                    attachment.image = image

                    DispatchQueue.main.async {
                        view.setNeedsDisplay()
                    }
                }

                attachment.accessibilityLabel = emoji.shortcode
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
