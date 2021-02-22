// Copyright © 2021 Metabolist. All rights reserved.

import Kingfisher
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

        var attachmentImageViews = Set<AnimatedImageView>()

        attributedText.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: attributedText.length)) { attachment, _, _ in
            guard let attachmentImageView = (attachment as? AnimatedTextAttachment)?.imageView else { return }

            attachmentImageViews.insert(attachmentImageView)
        }

        for subview in subviews {
            guard let attachmentImageView = subview as? AnimatedImageView else { continue }

            if !attachmentImageViews.contains(attachmentImageView) {
                attachmentImageView.removeFromSuperview()
            }
        }

        attributedText.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: attributedText.length),
            options: .longestEffectiveRangeNotRequired) { attachment, _, _ in
            guard let animatedAttachment = attachment as? AnimatedTextAttachment,
                  let imageBounds = animatedAttachment.imageBounds
            else { return }

            animatedAttachment.imageView.frame = imageBounds

            animatedAttachment.imageView.image = animatedAttachment.image
            animatedAttachment.imageView.contentMode = .scaleAspectFit
            animatedAttachment.imageView.center.y = center.y

            if animatedAttachment.imageView.superview != self {
                addSubview(animatedAttachment.imageView)
            }
        }
    }
}
