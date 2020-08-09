// Copyright © 2020 Metabolist. All rights reserved.

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import Kingfisher

extension NSMutableAttributedString {
    func insert(emojis: [Emoji], onImageLoad: @escaping (() -> Void)) {
        for emoji in emojis {
            let token = ":\(emoji.shortcode):"

            while let tokenRange = string.range(of: token) {
                let attachment = NSTextAttachment()
                let attachmentAttributedString = NSAttributedString(attachment: attachment)

                replaceCharacters(in: NSRange(tokenRange, in: string), with: attachmentAttributedString)

                KingfisherManager.shared.retrieveImage(with: emoji.url) {
                    guard case let .success(value) = $0 else { return }

                    attachment.image = value.image
                    onImageLoad()
                }
            }
        }
    }

    func resizeAttachments(toLineHeight lineHeight: CGFloat) {
        enumerateAttribute(.attachment, in: NSRange(location: 0, length: length), options: []) { attribute, _, _ in
            guard let attachment = attribute as? NSTextAttachment else { return }

            attachment.bounds = CGRect(x: 0, y: lineHeight * -0.25, width: lineHeight, height: lineHeight)
        }
    }
}
