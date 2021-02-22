// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit
import ViewModels

final class PollOptionButton: UIView {
    let button = UIButton()

    public var isSelected = false {
        didSet {
            imageView.image = isSelected ? selectedImage : image
            button.isSelected = isSelected
        }
    }

    private let label = AnimatedAttachmentLabel()
    private let imageView = UIImageView()
    private let image: UIImage?
    private let selectedImage: UIImage?

    // swiftlint:disable:next function_body_length
    init(title: String, emojis: [Emoji], multipleSelection: Bool, identityContext: IdentityContext) {
        image = UIImage(
            systemName: multipleSelection ? "square" : "circle",
            withConfiguration: UIImage.SymbolConfiguration(scale: .medium))
        selectedImage = UIImage(
            systemName: multipleSelection ? "checkmark.square" : "checkmark.circle",
            withConfiguration: UIImage.SymbolConfiguration(scale: .medium))

        super.init(frame: .zero)

        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = .defaultSpacing

        stackView.addArrangedSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)

        stackView.addArrangedSubview(label)
        label.font = .preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        let attributedTitle = NSMutableAttributedString(string: title)

        attributedTitle.insert(emojis: emojis, view: label, identityContext: identityContext)
        attributedTitle.resizeAttachments(toLineHeight: label.font.lineHeight)

        label.attributedText = attributedTitle

        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityAttributedLabel = attributedTitle

        let touchStartAction = UIAction { [weak self] _ in self?.alpha = 0.75 }

        button.addAction(touchStartAction, for: .touchDown)
        button.addAction(touchStartAction, for: .touchDragEnter)

        let touchEndAction = UIAction { [weak self] _ in self?.alpha = 1 }

        button.addAction(touchEndAction, for: .touchDragExit)
        button.addAction(touchEndAction, for: .touchUpInside)
        button.addAction(touchEndAction, for: .touchUpOutside)
        button.addAction(touchEndAction, for: .touchCancel)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
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
