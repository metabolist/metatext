// Copyright © 2021 Metabolist. All rights reserved.

import Kingfisher
import UIKit

final class EmojiView: UIView {
    private let imageView = UIImageView()
    private let emojiLabel = UILabel()
    private var emojiConfiguration: EmojiContentConfiguration

    init(configuration: EmojiContentConfiguration) {
        emojiConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyEmojiConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EmojiView: UIContentView {
    var configuration: UIContentConfiguration {
        get { emojiConfiguration }
        set {
            guard let emojiConfiguration = newValue as? EmojiContentConfiguration else { return }

            self.emojiConfiguration = emojiConfiguration

            applyEmojiConfiguration()
        }
    }
}

private extension EmojiView {
    func initialSetup() {
        layoutMargins = .init(
            top: .compactSpacing,
            left: .compactSpacing,
            bottom: .compactSpacing,
            right: .compactSpacing)

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        addSubview(emojiLabel)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.textAlignment = .center
        emojiLabel.adjustsFontSizeToFitWidth = true
        emojiLabel.font = .preferredFont(forTextStyle: .largeTitle)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            emojiLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            emojiLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            emojiLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            emojiLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])

        setupAccessibility()
    }

    func applyEmojiConfiguration() {
        imageView.isHidden = emojiConfiguration.emoji.system

        if case let .custom(emoji, _) = emojiConfiguration.emoji {
            imageView.isHidden = false
            emojiLabel.isHidden = true

            imageView.kf.setImage(with: emoji.url)
            accessibilityLabel = emoji.shortcode
        } else {
            imageView.isHidden = true
            emojiLabel.isHidden = false

            emojiLabel.text = emojiConfiguration.emoji.name
            accessibilityLabel = emojiConfiguration.emoji.name
        }
    }

    func setupAccessibility() {
        isAccessibilityElement = true
    }
}
