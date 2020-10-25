// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit

class PollOptionButton: UIButton {
    init(title: String, emoji: [Emoji], multipleSelection: Bool) {
        super.init(frame: .zero)

        titleLabel?.font = .preferredFont(forTextStyle: .callout)
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.numberOfLines = 0
        titleLabel?.lineBreakMode = .byWordWrapping
        contentHorizontalAlignment = .leading
        titleEdgeInsets = Self.titleEdgeInsets

        let attributedTitle = NSMutableAttributedString(string: title)

        attributedTitle.insert(emoji: emoji, view: titleLabel!)
        attributedTitle.resizeAttachments(toLineHeight: titleLabel!.font.lineHeight)
        setAttributedTitle(attributedTitle, for: .normal)
        setImage(
            UIImage(
                systemName: multipleSelection ? "square" : "circle",
                withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .normal)
        setImage(
            UIImage(
                systemName: multipleSelection ? "checkmark.square" : "checkmark.circle",
                withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .selected)

        setContentCompressionResistancePriority(.required, for: .vertical)

        heightAnchor.constraint(equalTo: titleLabel!.heightAnchor).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension PollOptionButton {
    static let titleEdgeInsets = UIEdgeInsets(top: 0, left: .compactSpacing, bottom: 0, right: .compactSpacing)
}
