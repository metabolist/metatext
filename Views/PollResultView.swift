// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit

class PollResultView: UIView {
    private let verticalStackView = UIStackView()
    private let horizontalStackView = UIStackView()
    private let titleLabel = UILabel()
    private let percentLabel = UILabel()
    private let percentView = UIProgressView()

    init(option: Poll.Option, emoji: [Emoji], selected: Bool, multipleSelection: Bool, votersCount: Int) {
        super.init(frame: .zero)

        addSubview(verticalStackView)
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.axis = .vertical
        verticalStackView.spacing = .compactSpacing

        verticalStackView.addArrangedSubview(horizontalStackView)
        horizontalStackView.spacing = .compactSpacing

        verticalStackView.addArrangedSubview(percentView)

        if selected {
            let imageView = UIImageView(
                image: UIImage(
                    systemName: multipleSelection ? "checkmark.square" : "checkmark.circle",
                    withConfiguration: UIImage.SymbolConfiguration(scale: .medium)))

            imageView.setContentHuggingPriority(.required, for: .horizontal)
            horizontalStackView.addArrangedSubview(imageView)
        }

        horizontalStackView.addArrangedSubview(titleLabel)
        titleLabel.font = .preferredFont(forTextStyle: .callout)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0

        horizontalStackView.addArrangedSubview(percentLabel)
        percentLabel.font = .preferredFont(forTextStyle: .callout)
        percentLabel.adjustsFontForContentSizeCategory = true
        percentLabel.setContentHuggingPriority(.required, for: .horizontal)

        let attributedTitle = NSMutableAttributedString(string: option.title)

        attributedTitle.insert(emoji: emoji, view: titleLabel)
        attributedTitle.resizeAttachments(toLineHeight: titleLabel.font.lineHeight)
        titleLabel.attributedText = attributedTitle

        let percent: Float

        if votersCount == 0 {
            percent = 0
        } else {
            percent = Float(option.votesCount) / Float(votersCount)
        }

        percentLabel.text = Self.percentFormatter.string(from: NSNumber(value: percent))
        percentView.progress = percent

        NSLayoutConstraint.activate([
            verticalStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            verticalStackView.topAnchor.constraint(equalTo: topAnchor),
            verticalStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            verticalStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension PollResultView {
    private static var percentFormatter: NumberFormatter = {
        let percentageFormatter = NumberFormatter()

        percentageFormatter.numberStyle = .percent

        return percentageFormatter
    }()
}
