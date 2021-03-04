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
    static let newStatusButtonDimension: Self = 58
    static let defaultShadowRadius: Self = 2
    static let systemMenuWidth: Self = 250
    static let systemMenuInset: Self = 15
}

extension Float {
    static let defaultShadowOpacity: Self = 0.25
}

extension CGSize {
    static let blurHashSize = Self(width: 32, height: 32)
}

extension CGRect {
    static let defaultContentsRect = Self(origin: .zero, size: .init(width: 1, height: 1))
}

extension TimeInterval {
    static let defaultAnimationDuration: Self = 0.5
    static let shortAnimationDuration = defaultAnimationDuration / 2
    static let longAnimationDuration: Self = 1

    static func zeroIfReduceMotion(_ duration: Self) -> Self { UIAccessibility.isReduceMotionEnabled ? 0 : duration }
}

extension UIImage {
    static let highlightedButtonBackground = UIColor(white: 0, alpha: 0.5).image()
}

extension UILayoutPriority {
    static let justBelowMax: Self = .init(999)
}
