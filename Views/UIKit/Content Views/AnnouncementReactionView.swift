// Copyright © 2021 Metabolist. All rights reserved.

import SDWebImage
import UIKit
import ViewModels

final class AnnouncementReactionView: UIView {
    private let nameLabel = UILabel()
    private let imageView = SDAnimatedImageView()
    private let countLabel = UILabel()
    private var announcementReactionConfiguration: AnnouncementReactionContentConfiguration

    init(configuration: AnnouncementReactionContentConfiguration) {
        announcementReactionConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyAnnouncementReactionConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AnnouncementReactionView: UIContentView {
    var configuration: UIContentConfiguration {
        get { announcementReactionConfiguration }
        set {
            guard let announcementReactionConfiguration = newValue as? AnnouncementReactionContentConfiguration else {
                return
            }

            self.announcementReactionConfiguration = announcementReactionConfiguration

            applyAnnouncementReactionConfiguration()
        }
    }
}

private extension AnnouncementReactionView {
    static let meBackgroundColor = UIColor.link.withAlphaComponent(0.5)
    static let backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.5)
    func initialSetup() {
        layer.cornerRadius = .defaultCornerRadius

        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = .defaultSpacing

        stackView.addArrangedSubview(imageView)
        imageView.contentMode = .scaleAspectFit

        stackView.addArrangedSubview(nameLabel)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textAlignment = .center
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.font = .preferredFont(forTextStyle: .body)

        stackView.addArrangedSubview(countLabel)
        countLabel.adjustsFontForContentSizeCategory = true
        countLabel.font = .preferredFont(forTextStyle: .headline)
        countLabel.textColor = .link

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalToConstant: .minimumButtonDimension / 2),
            imageView.heightAnchor.constraint(equalToConstant: .minimumButtonDimension / 2),
            nameLabel.widthAnchor.constraint(equalToConstant: .minimumButtonDimension / 2),
            nameLabel.heightAnchor.constraint(equalToConstant: .minimumButtonDimension / 2)
        ])

        isAccessibilityElement = true
    }

    func applyAnnouncementReactionConfiguration() {
        let viewModel = announcementReactionConfiguration.viewModel

        backgroundColor = viewModel.me ? Self.meBackgroundColor : Self.backgroundColor

        nameLabel.text = viewModel.name
        nameLabel.isHidden = viewModel.url != nil

        imageView.sd_setImage(with: viewModel.url)
        imageView.isHidden = viewModel.url == nil

        countLabel.text = String(viewModel.count)

        accessibilityLabel = viewModel.name.appendingWithSeparator(String(viewModel.count))
    }
}
