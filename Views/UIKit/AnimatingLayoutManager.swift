// Copyright © 2021 Metabolist. All rights reserved.

import Kingfisher
import UIKit

final class AnimatingLayoutManager: NSLayoutManager {
    weak var view: UIView?

    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let textStorage = textStorage else {
            super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)

            return
        }

        var attachmentImageViews = Set<AnimatedImageView>()

        textStorage.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: textStorage.length)) { attachment, _, _ in
            guard let attachmentImageView = (attachment as? AnimatedTextAttachment)?.imageView else { return }

            attachmentImageViews.insert(attachmentImageView)
        }

        for subview in view?.subviews ?? [] {
            guard let attachmentImageView = subview as? AnimatedImageView else { continue }

            if !attachmentImageViews.contains(attachmentImageView) {
                attachmentImageView.removeFromSuperview()
            }
        }

        textStorage.enumerateAttribute(
            .attachment,
            in: glyphsToShow,
            options: .longestEffectiveRangeNotRequired) { attachment, range, _ in
            guard let animatedAttachment = attachment as? AnimatedTextAttachment,
                  let textContainer = textContainer(forGlyphAt: range.location, effectiveRange: nil)
            else { return }

            animatedAttachment.imageView.frame = boundingRect(forGlyphRange: range, in: textContainer)
            animatedAttachment.imageView.image = animatedAttachment.image
            animatedAttachment.imageView.contentMode = .scaleAspectFit

            if animatedAttachment.imageView.superview != view {
                view?.addSubview(animatedAttachment.imageView)
            }
        }

        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
    }
}
