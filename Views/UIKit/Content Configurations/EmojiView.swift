// Copyright © 2021 Metabolist. All rights reserved.

import SDWebImage
import UIKit

final class EmojiView: UIView {
    private let imageView = SDAnimatedImageView()
    private let emojiLabel = UILabel()
    private var emojiConfiguration: EmojiContentConfiguration

    init(configuration: EmojiContentConfiguration) {
        emojiConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        setupAccessibility()
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
    }

    func applyEmojiConfiguration() {
        if emojiConfiguration.viewModel.system {
            emojiLabel.isHidden = false
            emojiLabel.text = emojiConfiguration.viewModel.name
            imageView.isHidden = true
        } else {
            emojiLabel.isHidden = true
            emojiLabel.text = nil
            imageView.isHidden = false

            let url: URL?

            if let urlString = emojiConfiguration.viewModel.url {
                url = URL(stringEscapingPath: urlString)
            } else {
                url = nil
            }

            imageView.sd_setImage(with: url)
        }

        accessibilityLabel = emojiConfiguration.viewModel.name
    }

    func setupAccessibility() {
        isAccessibilityElement = true
    }
}
