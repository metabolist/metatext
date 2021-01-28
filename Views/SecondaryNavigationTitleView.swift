// Copyright © 2021 Metabolist. All rights reserved.

import Kingfisher
import UIKit
import ViewModels

final class SecondaryNavigationTitleView: UIView {
    private let viewModel: NavigationViewModel
    private let avatarImageView = AnimatedImageView()
    private let displayNameLabel = UILabel()
    private let accountLabel = UILabel()
    private let stackView = UIStackView()

    init(viewModel: NavigationViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)

        initialSetup()
        applyViewModel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SecondaryNavigationTitleView {
    func initialSetup() {
        addSubview(avatarImageView)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.layer.cornerRadius = .barButtonItemDimension / 2
        avatarImageView.autoPlayAnimatedImage = viewModel.identityContext.appPreferences.animateAvatars == .everywhere
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .ultraCompactSpacing

        stackView.addArrangedSubview(displayNameLabel)
        displayNameLabel.adjustsFontForContentSizeCategory = true
        displayNameLabel.adjustsFontSizeToFitWidth = true
        displayNameLabel.minimumScaleFactor = 0.5
        displayNameLabel.font = .preferredFont(forTextStyle: .headline)

        stackView.addArrangedSubview(accountLabel)
        accountLabel.adjustsFontForContentSizeCategory = true
        accountLabel.adjustsFontSizeToFitWidth = true
        accountLabel.minimumScaleFactor = 0.5
        accountLabel.font = .preferredFont(forTextStyle: .footnote)
        accountLabel.textColor = .secondaryLabel

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: .barButtonItemDimension),
            avatarImageView.heightAnchor.constraint(equalToConstant: .barButtonItemDimension),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: .defaultSpacing),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func applyViewModel() {
        avatarImageView.kf.setImage(with: viewModel.identityContext.identity.image)

        if let displayName = viewModel.identityContext.identity.account?.displayName,
           !displayName.isEmpty {
            let mutableDisplayName = NSMutableAttributedString(string: displayName)

            if let emojis = viewModel.identityContext.identity.account?.emojis {
                mutableDisplayName.insert(emojis: emojis, view: displayNameLabel)
                mutableDisplayName.resizeAttachments(toLineHeight: displayNameLabel.font.lineHeight)
            }

            displayNameLabel.attributedText = mutableDisplayName
        } else {
            displayNameLabel.isHidden = true
        }

        accountLabel.text = viewModel.identityContext.identity.handle
    }
}
