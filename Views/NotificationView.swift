// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit

class NotificationView: UIView {
    private let iconImageView = UIImageView()
    private let typeLabel = UILabel()
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
    func initialSetup() {
        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = .compactSpacing

        stackView.addArrangedSubview(iconImageView)
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)

        stackView.addArrangedSubview(typeLabel)
        typeLabel.font = .preferredFont(forTextStyle: .body)
        typeLabel.adjustsFontForContentSizeCategory = true

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor)
        ])
    }

    func applyNotificationConfiguration() {
        let viewModel = notificationConfiguration.viewModel

        switch viewModel.type {
        case .follow:
            typeLabel.attributedText = "notifications.followed-you".localizedBolding(
                displayName: viewModel.accountViewModel.displayName,
                emoji: viewModel.accountViewModel.emoji,
                label: typeLabel)
            iconImageView.tintColor = nil
        case .reblog:
            typeLabel.attributedText = "notifications.reblogged-your-status".localizedBolding(
                displayName: viewModel.accountViewModel.displayName,
                emoji: viewModel.accountViewModel.emoji,
                label: typeLabel)
            iconImageView.tintColor = .systemGreen
        case .favourite:
            typeLabel.attributedText = "notifications.favourited-your-status".localizedBolding(
                displayName: viewModel.accountViewModel.displayName,
                emoji: viewModel.accountViewModel.emoji,
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
                emoji: viewModel.accountViewModel.emoji,
                label: typeLabel)
            iconImageView.tintColor = nil
        }

        iconImageView.image = UIImage(
            systemName: viewModel.type.systemImageName,
            withConfiguration: UIImage.SymbolConfiguration(scale: .medium))
    }
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
