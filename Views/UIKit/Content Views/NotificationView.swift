// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import SDWebImage
import UIKit
import ViewModels

final class NotificationView: UIView {
    private let iconImageView = UIImageView()
    private let avatarImageView = SDAnimatedImageView()
    private let avatarButton = UIButton()
    private let typeLabel = AnimatedAttachmentLabel()
    private let timeLabel = UILabel()
    private let displayNameLabel = AnimatedAttachmentLabel()
    private let accountLabel = UILabel()
    private let statusBodyView = StatusBodyView()
    private var notificationConfiguration: NotificationContentConfiguration

    init(configuration: NotificationContentConfiguration) {
        notificationConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyNotificationConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NotificationView {
    static func estimatedHeight(width: CGFloat,
                                identityContext: IdentityContext,
                                notification: MastodonNotification,
                                configuration: CollectionItem.StatusConfiguration?) -> CGFloat {
        let bodyWidth = width - .defaultSpacing - .avatarDimension

        var height = CGFloat.defaultSpacing * 2
            + UIFont.preferredFont(forTextStyle: .headline).lineHeight
            + .compactSpacing

        if let status = notification.status {
            height += StatusBodyView.estimatedHeight(
                width: bodyWidth,
                identityContext: identityContext,
                status: status,
                configuration: configuration ?? .default)
        } else {
            height += UIFont.preferredFont(forTextStyle: .headline).lineHeight
                + .compactSpacing
                + UIFont.preferredFont(forTextStyle: .subheadline).lineHeight
        }

        return height
    }
}

extension NotificationView: UIContentView {
    var configuration: UIContentConfiguration {
        get { notificationConfiguration }
        set {
            guard let notificationConfiguration = newValue as? NotificationContentConfiguration else { return }

            self.notificationConfiguration = notificationConfiguration

            applyNotificationConfiguration()
        }
    }
}

private extension NotificationView {
    // swiftlint:disable function_body_length
    func initialSetup() {
        let containerStackView = UIStackView()
        let sideStackView = UIStackView()
        let typeTimeStackView = UIStackView()
        let mainStackView = UIStackView()

        addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.spacing = .defaultSpacing
        containerStackView.alignment = .top

        sideStackView.axis = .vertical
        sideStackView.alignment = .trailing
        sideStackView.spacing = .compactSpacing
        sideStackView.addArrangedSubview(iconImageView)
        sideStackView.addArrangedSubview(avatarImageView)
        containerStackView.addArrangedSubview(sideStackView)

        typeTimeStackView.spacing = .compactSpacing
        typeTimeStackView.alignment = .top

        mainStackView.axis = .vertical
        mainStackView.spacing = .compactSpacing
        typeTimeStackView.addArrangedSubview(typeLabel)
        typeTimeStackView.addArrangedSubview(timeLabel)
        mainStackView.addArrangedSubview(typeTimeStackView)
        mainStackView.addArrangedSubview(statusBodyView)
        mainStackView.addArrangedSubview(displayNameLabel)
        mainStackView.addArrangedSubview(accountLabel)
        containerStackView.addArrangedSubview(mainStackView)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)

        avatarImageView.layer.cornerRadius = .avatarDimension / 2
        avatarImageView.clipsToBounds = true

        let avatarHeightConstraint = avatarImageView.heightAnchor.constraint(equalToConstant: .avatarDimension)

        avatarHeightConstraint.priority = .justBelowMax

        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.addSubview(avatarButton)
        avatarImageView.isUserInteractionEnabled = true
        avatarButton.setBackgroundImage(.highlightedButtonBackground, for: .highlighted)

        avatarButton.addAction(
            UIAction { [weak self] _ in self?.notificationConfiguration.viewModel.accountSelected() },
            for: .touchUpInside)

        typeLabel.font = .preferredFont(forTextStyle: .headline)
        typeLabel.adjustsFontForContentSizeCategory = true
        typeLabel.numberOfLines = 0

        timeLabel.font = .preferredFont(forTextStyle: .subheadline)
        timeLabel.adjustsFontForContentSizeCategory = true
        timeLabel.textColor = .secondaryLabel
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)

        statusBodyView.alpha = 0.5
        statusBodyView.isUserInteractionEnabled = false

        displayNameLabel.font = .preferredFont(forTextStyle: .headline)
        displayNameLabel.adjustsFontForContentSizeCategory = true
        displayNameLabel.numberOfLines = 0

        accountLabel.font = .preferredFont(forTextStyle: .subheadline)
        accountLabel.adjustsFontForContentSizeCategory = true
        accountLabel.textColor = .secondaryLabel
        accountLabel.numberOfLines = 0

        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            containerStackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            avatarHeightConstraint,
            sideStackView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            iconImageView.centerYAnchor.constraint(equalTo: typeLabel.centerYAnchor),
            avatarButton.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            avatarButton.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            avatarButton.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            avatarButton.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor)
        ])

        isAccessibilityElement = true
    }

    func applyNotificationConfiguration() {
        let viewModel = notificationConfiguration.viewModel
        var imageName = viewModel.type.systemImageName
        avatarImageView.sd_setImage(with: viewModel.accountViewModel.avatarURL())

        switch viewModel.type {
        case .follow:
            typeLabel.attributedText = "notifications.followed-you-%@".localizedBolding(
                displayName: viewModel.accountViewModel.displayName,
                emojis: viewModel.accountViewModel.emojis,
                label: typeLabel,
                identityContext: viewModel.identityContext)
            iconImageView.tintColor = nil
        case .reblog:
            typeLabel.attributedText = "notifications.reblogged-your-status-%@".localizedBolding(
                displayName: viewModel.accountViewModel.displayName,
                emojis: viewModel.accountViewModel.emojis,
                label: typeLabel,
                identityContext: viewModel.identityContext)
            iconImageView.tintColor = .systemGreen
        case .favourite:
            let label: String
            let color: UIColor
            switch viewModel.identityContext.appPreferences.displayFavoritesAs {
            case .favorites:
                label = "notifications.favourited-your-status-%@"
                color = .systemYellow
            case .likes:
                label = "notifications.liked-your-status-%@"
                color = .systemRed
                imageName = "heart.fill"
            }
            typeLabel.attributedText = label.localizedBolding(
                displayName: viewModel.accountViewModel.displayName,
                emojis: viewModel.accountViewModel.emojis,
                label: typeLabel,
                identityContext: viewModel.identityContext)
            iconImageView.tintColor = color
        case .poll:
            typeLabel.text = NSLocalizedString(
                viewModel.accountViewModel.isSelf
                    ? "notifications.your-poll-ended"
                    : "notifications.poll-ended",
                comment: "")
            iconImageView.tintColor = nil
        default:
            typeLabel.attributedText = "notifications.unknown-%@".localizedBolding(
                displayName: viewModel.accountViewModel.displayName,
                emojis: viewModel.accountViewModel.emojis,
                label: typeLabel,
                identityContext: viewModel.identityContext)
            iconImageView.tintColor = nil
        }

        if viewModel.statusViewModel == nil {
            let mutableDisplayName = NSMutableAttributedString(string: viewModel.accountViewModel.displayName)

            mutableDisplayName.insert(emojis: viewModel.accountViewModel.emojis,
                                      view: displayNameLabel,
                                      identityContext: viewModel.identityContext)
            mutableDisplayName.resizeAttachments(toLineHeight: displayNameLabel.font.lineHeight)
            displayNameLabel.attributedText = mutableDisplayName
            accountLabel.text = viewModel.accountViewModel.accountName
            statusBodyView.isHidden = true
            displayNameLabel.isHidden = false
            accountLabel.isHidden = false
        } else {
            statusBodyView.viewModel = viewModel.statusViewModel
            statusBodyView.isHidden = false
            displayNameLabel.isHidden = true
            accountLabel.isHidden = true
        }

        timeLabel.text = viewModel.time
        timeLabel.accessibilityLabel = viewModel.accessibilityTime

        iconImageView.image = UIImage(
            systemName: imageName,
            withConfiguration: UIImage.SymbolConfiguration(scale: .medium))

        let accessibilityAttributedLabel = NSMutableAttributedString(string: "")

        if let typeText = typeLabel.attributedText {
            accessibilityAttributedLabel.appendWithSeparator(typeText)
        }

        if !statusBodyView.isHidden,
           let statusBodyAccessibilityAttributedLabel = statusBodyView.accessibilityAttributedLabel {
            accessibilityAttributedLabel.appendWithSeparator(statusBodyAccessibilityAttributedLabel)
        } else if !accountLabel.isHidden, let accountText = accountLabel.text {
            accessibilityAttributedLabel.appendWithSeparator(accountText)
        }

        if let accessibilityTime = viewModel.accessibilityTime {
            accessibilityAttributedLabel.appendWithSeparator(accessibilityTime)
        }

        self.accessibilityAttributedLabel = accessibilityAttributedLabel

        accessibilityCustomActions = [
            UIAccessibilityCustomAction(
                name: NSLocalizedString("notification.accessibility.view-profile", comment: "")) { [weak self] _ in
                self?.notificationConfiguration.viewModel.accountSelected()

                return true
            }
        ]
    }
    // swiftlint:enable function_body_length
}
