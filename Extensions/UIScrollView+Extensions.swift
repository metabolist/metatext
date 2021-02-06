// Copyright © 2021 Metabolist. All rights reserved.

import UIKit

extension UIScrollView: ScrollableToTop {
    func scrollToTop(animated: Bool) {
        setContentOffset(.init(x: 0, y: -adjustedContentInset.top), animated: animated)
    }
}
