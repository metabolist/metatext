// Copyright © 2021 Metabolist. All rights reserved.

import Kingfisher
import UIKit

final class IdentityView: UIView {
    let imageView = AnimatedImageView()
    let nameLabel = UILabel()
    let secondaryLabel = UILabel()

    private var identityConfiguration: IdentityContentConfiguration

    init(configuration: IdentityContentConfiguration) {
        identityConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyIdentityConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension IdentityView: UIContentView {
    var configuration: UIContentConfiguration {
        get { identityConfiguration }
        set {
            guard let identityConfiguration = newValue as? IdentityContentConfiguration else { return }

            self.identityConfiguration = identityConfiguration

            applyIdentityConfiguration()
        }
    }
}

private extension IdentityView {
    func initialSetup() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = .avatarDimension / 2
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill

        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .compactSpacing

        stackView.addArrangedSubview(nameLabel)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.numberOfLines = 0

        stackView.addArrangedSubview(secondaryLabel)
        secondaryLabel.adjustsFontForContentSizeCategory = true
        secondaryLabel.font = .preferredFont(forTextStyle: .subheadline)
        secondaryLabel.numberOfLines = 0
        secondaryLabel.textColor = .secondaryLabel

        let imageViewHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: .avatarDimension)

        imageViewHeightConstraint.priority = .justBelowMax

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            imageViewHeightConstraint,
            imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: .defaultSpacing),
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }

    func applyIdentityConfiguration() {
        let viewModel = identityConfiguration.viewModel

        imageView.kf.setImage(with: viewModel.identity.image)
        imageView.autoPlayAnimatedImage = viewModel.identityContext.appPreferences.animateAvatars == .everywhere

        if let displayName = viewModel.identity.account?.displayName,
           !displayName.isEmpty {
            let mutableName = NSMutableAttributedString(string: displayName)

            if let emojis = viewModel.identity.account?.emojis {
                mutableName.insert(emojis: emojis, view: nameLabel)
                mutableName.resizeAttachments(toLineHeight: nameLabel.font.lineHeight)
            }

            nameLabel.attributedText = mutableName
        } else {
            nameLabel.isHidden = true
        }

        secondaryLabel.text = viewModel.identity.handle
    }
}
