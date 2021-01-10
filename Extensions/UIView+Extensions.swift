// Copyright © 2021 Metabolist. All rights reserved.

import Mastodon
import UIKit

extension UIView {
    private static let defaultContentsRectSize = CGSize(width: 1, height: 1)

    func setContentsRect(focus: Attachment.Meta.Focus, mediaSize: CGSize) {
        let aspectRatio = mediaSize.width / mediaSize.height
        let viewAspectRatio = bounds.width / bounds.height
        var origin = CGPoint.zero

        if viewAspectRatio > aspectRatio {
            let mediaProportionalHeight = mediaSize.height * bounds.width / mediaSize.width
            let maxPan = (mediaProportionalHeight - bounds.height) / (2 * mediaProportionalHeight)

            origin.y = CGFloat(-focus.y) * maxPan
        } else {
            let mediaProportionalWidth = mediaSize.width * bounds.height / mediaSize.height
            let maxPan = (mediaProportionalWidth - bounds.width) / (2 * mediaProportionalWidth)

            origin.x = CGFloat(focus.x) * maxPan
        }

        layer.contentsRect = CGRect(origin: origin, size: Self.defaultContentsRectSize)
    }
}
