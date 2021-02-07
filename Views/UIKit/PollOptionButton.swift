// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit

final class PollOptionButton: UIButton {
    init(title: String, emojis: [Emoji], multipleSelection: Bool) {
        super.init(frame: .zero)

        titleLabel?.font = .preferredFont(forTextStyle: .callout)
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.numberOfLines = 0
        titleLabel?.lineBreakMode = .byWordWrapping
        contentHorizontalAlignment = .leading

        let attributedTitle = NSMutableAttributedString(string: title)

        attributedTitle.insert(emojis: emojis, view: titleLabel!)
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

        imageView?.translatesAutoresizingMaskIntoConstraints = false
        imageView?.widthAnchor.constraint(greaterThanOrEqualToConstant: .minimumButtonDimension).isActive = true
        imageView?.contentMode = .scaleAspectFit

        heightAnchor.constraint(equalTo: titleLabel!.heightAnchor).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PollOptionButton {
    static func estimatedHeight(width: CGFloat, title: String) -> CGFloat {
        title.height(width: width, font: .preferredFont(forTextStyle: .callout))
    }
}
