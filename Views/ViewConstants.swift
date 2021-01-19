// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

extension CGFloat {
    static let defaultSpacing: Self = 8
    static let compactSpacing: Self = 4
    static let ultraCompactSpacing: Self = 1
    static let defaultCornerRadius: Self = 8
    static let avatarDimension: Self = 50
    static let hairline = 1 / UIScreen.main.scale
    static let minimumButtonDimension: Self = 44
    static let barButtonItemDimension: Self = 28
    static let newStatusButtonDimension: CGFloat = 54
    static let defaultShadowRadius: CGFloat = 2
}

extension CGRect {
    static let defaultContentsRect = Self(origin: .zero, size: .init(width: 1, height: 1))
}

extension TimeInterval {
    static let defaultAnimationDuration: Self = 0.5
    static let shortAnimationDuration = defaultAnimationDuration / 2

    static func zeroIfReduceMotion(_ duration: Self) -> Self { UIAccessibility.isReduceMotionEnabled ? 0 : duration }
}

extension UIImage {
    static let highlightedButtonBackground = UIColor(white: 0, alpha: 0.5).image()
}

extension UILayoutPriority {
    static let justBelowMax: Self = .init(999)
}
