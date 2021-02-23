// Copyright © 2021 Metabolist. All rights reserved.

import SDWebImage
import UIKit

final class AnimatedTextAttachment: NSTextAttachment {
    var imageURL: URL?
    var imageView = SDAnimatedImageView()
    var imageBounds: CGRect?

    override func image(forBounds imageBounds: CGRect,
                        textContainer: NSTextContainer?,
                        characterIndex charIndex: Int) -> UIImage? {
        if let textContainer = textContainer,
           let textContainerImageBounds = textContainer.layoutManager?.boundingRect(
            forGlyphRange: NSRange(location: charIndex, length: 1),
            in: textContainer),
           textContainerImageBounds != .zero {
            self.imageBounds = textContainerImageBounds
        } else {
            self.imageBounds = imageBounds
        }

        return nil // rendered by AnimatingLayoutManager or AnimatedAttachmentLabel
    }
}
