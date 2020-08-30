// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import Kingfisher
import Mastodon

extension NSMutableAttributedString {
    func insert(emoji: [Emoji], view: UIView) {
        for emoji in emoji {
            let token = ":\(emoji.shortcode):"

            while let tokenRange = string.range(of: token) {
                let attachment = NSTextAttachment()

                attachment.kf.setImage(with: emoji.url, attributedView: view)
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
}
