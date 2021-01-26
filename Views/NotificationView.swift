// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import Mastodon
import UIKit
import ViewModels

final class NotificationView: UIView {
    private let iconImageView = UIImageView()
    private let avatarImageView = AnimatedImageView()
    private let avatarButton = UIButton()
    private let typeLabel = UILabel()
    private let displayNameLabel = UILabel()
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
        let mainStackView = UIStackView()

        addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.spacing = .defaultSpacing

        sideStackView.axis = .vertical
        sideStackView.alignment = .trailing
        sideStackView.spacing = .compactSpacing
        sideStackView.addArrangedSubview(iconImageView)
        sideStackView.addArrangedSubview(avatarImageView)
        sideStackView.addArrangedSubview(UIView())
        containerStackView.addArrangedSubview(sideStackView)

        mainStackView.axis = .vertical
        mainStackView.spacing = .compactSpacing
        mainStackView.addArrangedSubview(typeLabel)
        mainStackView.addSubview(UIView())
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
    }

    func applyNotificationConfiguration() {
        let viewModel = notificationConfiguration.viewModel

        avatarImageView.kf.setImage(with: viewModel.accountViewModel.avatarURL())

        switch viewModel.type {
        case .follow:
            typeLabel.attributedText = "notifications.followed-you".localizedBolding(
                displayName: viewModel.accountViewModel.displayName,
                emojis: viewModel.accountViewModel.emojis,
                label: typeLabel)
            iconImageView.tintColor = nil
        case .reblog:
            typeLabel.attributedText = "notifications.reblogged-your-status".localizedBolding(
                displayName: viewModel.accountViewModel.displayName,
                emojis: viewModel.accountViewModel.emojis,
                label: typeLabel)
            iconImageView.tintColor = .systemGreen
        case .favourite:
            typeLabel.attributedText = "notifications.favourited-your-status".localizedBolding(
                displayName: viewModel.accountViewModel.displayName,
                emojis: viewModel.accountViewModel.emojis,
                label: typeLabel)
            iconImageView.tintColor = .systemYellow
        case .poll:
            typeLabel.text = NSLocalizedString(
                viewModel.accountViewModel.isSelf
                    ? "notifications.your-poll-ended"
                    : "notifications.poll-ended",
                comment: "")
            iconImageView.tintColor = nil
        default:
            typeLabel.attributedText = "notifications.unknown".localizedBolding(
                displayName: viewModel.accountViewModel.displayName,
                emojis: viewModel.accountViewModel.emojis,
                label: typeLabel)
            iconImageView.tintColor = nil
        }

        if viewModel.statusViewModel == nil {
            let mutableDisplayName = NSMutableAttributedString(string: viewModel.accountViewModel.displayName)

            mutableDisplayName.insert(emojis: viewModel.accountViewModel.emojis, view: displayNameLabel)
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

        iconImageView.image = UIImage(
            systemName: viewModel.type.systemImageName,
            withConfiguration: UIImage.SymbolConfiguration(scale: .medium))
    }
    // swiftlint:enable function_body_length
}

extension MastodonNotification.NotificationType {
    var systemImageName: String {
        switch self {
        case .follow, .followRequest:
            return "person.badge.plus"
        case .reblog:
            return "arrow.2.squarepath"
        case .favourite:
            return "star.fill"
        case .poll:
            return "chart.bar.doc.horizontal"
        case .mention, .unknown:
            return "at"
        }
    }
}
