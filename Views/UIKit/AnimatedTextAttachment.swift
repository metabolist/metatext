// Copyright © 2021 Metabolist. All rights reserved.

import SDWebImage
import UIKit

final class AnimatedTextAttachment: NSTextAttachment {
    let imageView = SDAnimatedImageView()
    private(set) var imageBounds: CGRect?

    override func image(forBounds imageBounds: CGRect,
                        textContainer: NSTextContainer?,
                        characterIndex charIndex: Int) -> UIImage? {
        if let textContainer = textContainer,
           let layoutManager = textContainer.layoutManager,
           let textContainerImageBounds = textContainer.layoutManager?.boundingRect(
            forGlyphRange: NSRange(location: layoutManager.glyphIndexForCharacter(at: charIndex), length: 1),
            in: textContainer),
           textContainerImageBounds != .zero {
            self.imageBounds = textContainerImageBounds
        } else {
            // Labels sometimes, but not always, end up in this path
            self.imageBounds = imageBounds
        }

        return nil // rendered by AnimatingLayoutManager or AnimatedAttachmentLabel
    }
}
