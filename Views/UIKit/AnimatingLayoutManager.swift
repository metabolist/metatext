// Copyright © 2021 Metabolist. All rights reserved.

import SDWebImage
import UIKit

final class AnimatingLayoutManager: NSLayoutManager {
    weak var view: UIView?

    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let textStorage = textStorage else {
            super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)

            return
        }

        var attachmentImageViews = Set<SDAnimatedImageView>()

        textStorage.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: textStorage.length)) { attachment, _, _ in
            guard let animatedAttachment = attachment as? AnimatedTextAttachment,
                  let imageBounds = animatedAttachment.imageBounds
            else { return }

            animatedAttachment.imageView.frame = imageBounds
            animatedAttachment.imageView.contentMode = .scaleAspectFit

            if animatedAttachment.imageView.superview != view {
                view?.addSubview(animatedAttachment.imageView)
            }

            attachmentImageViews.insert(animatedAttachment.imageView)
        }

        for subview in view?.subviews ?? [] {
            guard let attachmentImageView = subview as? SDAnimatedImageView else { continue }

            if !attachmentImageViews.contains(attachmentImageView) {
                attachmentImageView.removeFromSuperview()
            }
        }

        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
    }
}
