// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import Mastodon
import UIKit
import ViewModels

final class CardView: UIView {
    let imageView = UIImageView()
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    let urlLabel = UILabel()
    let button = UIButton()

    var viewModel: CardViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }

            imageView.isHidden = viewModel.imageURL == nil
            imageView.kf.setImage(with: viewModel.imageURL)

            titleLabel.text = viewModel.title
            descriptionLabel.text = viewModel.description
            descriptionLabel.isHidden = descriptionLabel.text == "" || descriptionLabel.text == titleLabel.text

            if
                let host = viewModel.url.host, host.hasPrefix("www."),
                let withoutWww = host.components(separatedBy: "www.").last {
                urlLabel.text = withoutWww
            } else {
                urlLabel.text = viewModel.url.host
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CardView {
    static func estimatedHeight(width: CGFloat,
                                identityContext: IdentityContext,
                                status: Status,
                                configuration: CollectionItem.StatusConfiguration) -> CGFloat {
        if status.displayStatus.card != nil {
            return round(UIFont.preferredFont(forTextStyle: .headline).lineHeight
                            + UIFont.preferredFont(forTextStyle: .subheadline).lineHeight
                            + UIFont.preferredFont(forTextStyle: .footnote).lineHeight
                            + .defaultSpacing * 2
                            + .compactSpacing * 2)
        } else {
            return 0
        }
    }
}

private extension CardView {
    // swiftlint:disable:next function_body_length
    func initialSetup() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = .defaultCornerRadius
        clipsToBounds = true

        let stackView = UIStackView()
        let innerStackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(.highlightedButtonBackground, for: .highlighted)

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(innerStackView)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        innerStackView.axis = .vertical
        innerStackView.isLayoutMarginsRelativeArrangement = true
        innerStackView.directionalLayoutMargins =
            .init(top: .defaultSpacing, leading: .defaultSpacing, bottom: .defaultSpacing, trailing: .defaultSpacing)
        innerStackView.spacing = .compactSpacing
        innerStackView.addArrangedSubview(titleLabel)
        innerStackView.addArrangedSubview(descriptionLabel)
        innerStackView.addArrangedSubview(urlLabel)

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        urlLabel.font = .preferredFont(forTextStyle: .footnote)
        urlLabel.adjustsFontForContentSizeCategory = true
        urlLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        urlLabel.textColor = .secondaryLabel

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.heightAnchor.constraint(equalTo: innerStackView.heightAnchor),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
        ])
    }
}
