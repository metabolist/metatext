// Copyright © 2021 Metabolist. All rights reserved.

import UIKit

final class CapsuleLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = inset
        invalidateIntrinsicContentSize()
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: .init(top: 0, left: inset, bottom: 0, right: inset)))
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize

        size.width += inset * 2

        return size
    }
}

private extension CapsuleLabel {
    var inset: CGFloat { bounds.height / 2 }

    func initialSetup() {
        backgroundColor = .secondarySystemBackground
        textColor = .secondaryLabel
        font = UIFont.preferredFont(forTextStyle: .footnote)
        adjustsFontForContentSizeCategory = true
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        clipsToBounds = true
    }
}
