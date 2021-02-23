// Copyright © 2021 Metabolist. All rights reserved.

import SDWebImage
import UIKit

final class AnimatedAttachmentLabel: UILabel, EmojiInsertable {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect)

        guard let attributedText = attributedText else { return }

        var attachmentImageViews = Set<SDAnimatedImageView>()

        attributedText.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: attributedText.length),
            options: .longestEffectiveRangeNotRequired) { attachment, _, _ in
            guard let animatedAttachment = attachment as? AnimatedTextAttachment,
                  let imageBounds = animatedAttachment.imageBounds
            else { return }

            animatedAttachment.imageView.frame = imageBounds
            animatedAttachment.imageView.contentMode = .scaleAspectFit

            if animatedAttachment.imageView.superview != self {
                addSubview(animatedAttachment.imageView)
            }

            attachmentImageViews.insert(animatedAttachment.imageView)
        }

        for subview in subviews {
            guard let attachmentImageView = subview as? SDAnimatedImageView else { continue }

            if !attachmentImageViews.contains(attachmentImageView) {
                attachmentImageView.removeFromSuperview()
            }
        }
    }
}
