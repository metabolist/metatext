// Copyright © 2021 Metabolist. All rights reserved.

import UIKit

final class CapsuleButton: UIButton {
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

        layer.cornerRadius = bounds.height / 2
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? Self.highlightedColor : .link
        }
    }

    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? .link : UIColor.link.withAlphaComponent(0.5)
        }
    }
}

private extension CapsuleButton {
    static let highlightedColor: UIColor = {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor.link.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return UIColor(hue: hue, saturation: saturation, brightness: brightness * 3 / 4, alpha: alpha)
    }()

    func initialSetup() {
        backgroundColor = .link
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.font = .preferredFont(forTextStyle: .headline)
        setTitleColor(.white, for: .normal)
        setTitleColor(.lightText, for: .highlighted)
        setTitleColor(.lightText, for: .disabled)
    }
}
