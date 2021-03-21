// Copyright © 2020 Metabolist. All rights reserved.

import SDWebImage
import UIKit
import ViewModels

final class AccountHeaderView: UIView {
    let headerImageBackgroundView = UIView()
    let headerImageView = SDAnimatedImageView()
    let headerButton = UIButton()
    let avatarBackgroundView = UIView()
    let avatarImageView = SDAnimatedImageView()
    let avatarButton = UIButton()
    let relationshipButtonsStackView = UIStackView()
    let directMessageButton = UIButton()
    let followButton = UIButton(type: .system)
    let unfollowButton = UIButton(type: .system)
    let notifyButton = UIButton()
    let unnotifyButton = UIButton()
    let displayNameLabel = AnimatedAttachmentLabel()
    let accountStackView = UIStackView()
    let accountLabel = CopyableLabel()
    let lockedImageView = UIImageView()
    let followsYouLabel = CapsuleLabel()
    let mutedLabel = CapsuleLabel()
    let blockedLabel = CapsuleLabel()
    let statusCountJoinedStackView = UIStackView()
    let statusCountLabel = UILabel()
    let statusCountJoinedSeparatorLabel = UILabel()
    let joinedLabel = UILabel()
    let fieldsStackView = UIStackView()
    let noteTextView = TouchFallthroughTextView()
    let followStackView = UIStackView()
    let followingButton = UIButton()
    let followersButton = UIButton()
    let segmentedControl = UISegmentedControl()
    let unavailableLabel = UILabel()

    var viewModel: ProfileViewModel {
        didSet {
            if let accountViewModel = viewModel.accountViewModel {
                headerImageView.sd_setImage(with: accountViewModel.headerURL) { [weak self] image, _, _, _ in
                    if let image = image, image.size != Self.missingHeaderImageSize {
                        self?.headerButton.isEnabled = true
                    }
                }
                headerImageView.tag = accountViewModel.headerURL.hashValue
                headerButton.accessibilityLabel = String.localizedStringWithFormat(
                    NSLocalizedString("account.header.accessibility-label-%@", comment: ""),
                    accountViewModel.displayName)
                avatarImageView.sd_setImage(with: accountViewModel.avatarURL(profile: true))
                avatarImageView.tag = accountViewModel.avatarURL(profile: true).hashValue
                avatarButton.accessibilityLabel = String.localizedStringWithFormat(
                    NSLocalizedString("account.avatar.accessibility-label-%@", comment: ""),
                    accountViewModel.displayName)

                if !accountViewModel.isSelf, let relationship = accountViewModel.relationship {
                    followsYouLabel.isHidden = !relationship.followedBy
                    mutedLabel.isHidden = !relationship.muting
                    blockedLabel.isHidden = !relationship.blocking
                    followButton.setTitle(
                        NSLocalizedString(
                            accountViewModel.isLocked ? "account.request" : "account.follow",
                            comment: ""),
                        for: .normal)
                    followButton.isHidden = relationship.following || relationship.requested
                    unfollowButton.isHidden = !(relationship.following || relationship.requested)
                    unfollowButton.setTitle(
                        NSLocalizedString(
                            relationship.requested ? "account.request.cancel" : "account.following",
                            comment: ""),
                        for: .normal)

                    if relationship.following, let notifying = relationship.notifying {
                        if notifying {
                            notifyButton.isHidden = true
                            unnotifyButton.isHidden = false
                        } else {
                            notifyButton.isHidden = false
                            unnotifyButton.isHidden = true
                        }
                    } else {
                        notifyButton.isHidden = true
                        unnotifyButton.isHidden = true
                    }

                    relationshipButtonsStackView.isHidden = false
                    unavailableLabel.isHidden = !relationship.blockedBy
                } else {
                    relationshipButtonsStackView.isHidden = true
                    unavailableLabel.isHidden = true
                }

                if accountViewModel.displayName.isEmpty {
                    displayNameLabel.isHidden = true
                } else {
                    let mutableDisplayName = NSMutableAttributedString(string: accountViewModel.displayName)

                    mutableDisplayName.insert(emojis: accountViewModel.emojis,
                                              view: displayNameLabel,
                                              identityContext: viewModel.identityContext)
                    mutableDisplayName.resizeAttachments(toLineHeight: displayNameLabel.font.lineHeight)
                    displayNameLabel.attributedText = mutableDisplayName
                }

                accountLabel.text = accountViewModel.accountName
                lockedImageView.isHidden = !accountViewModel.isLocked

                var accountStackViewAccessibilityLabel = accountViewModel.accountName

                if !lockedImageView.isHidden {
                    accountStackViewAccessibilityLabel
                        .appendWithSeparator(NSLocalizedString("account.locked.accessibility-label", comment: ""))
                }

                if !followsYouLabel.isHidden, let followsYouText = followsYouLabel.text {
                    accountStackViewAccessibilityLabel.appendWithSeparator(followsYouText)
                }

                accountStackView.accessibilityLabel = accountStackViewAccessibilityLabel

                let statusCountFormat: String

                switch viewModel.identityContext.appPreferences.statusWord {
                case .toot:
                    statusCountFormat = NSLocalizedString("statuses.count.toot-%ld", comment: "")
                case .post:
                    statusCountFormat = NSLocalizedString("statuses.count.post-%ld", comment: "")
                }

                statusCountLabel.text = String.localizedStringWithFormat(
                    statusCountFormat,
                    accountViewModel.statusesCount)
                joinedLabel.text = String.localizedStringWithFormat(
                    NSLocalizedString("account.joined-%@", comment: ""),
                    Self.joinedDateFormatter.string(from: accountViewModel.joined))

                for view in fieldsStackView.arrangedSubviews {
                    fieldsStackView.removeArrangedSubview(view)
                    view.removeFromSuperview()
                }

                for identityProof in accountViewModel.identityProofs {
                    let fieldView = AccountFieldView(
                        name: identityProof.provider,
                        value: NSAttributedString(
                            string: identityProof.providerUsername,
                            attributes: [.link: identityProof.profileUrl]),
                        verifiedAt: identityProof.updatedAt,
                        emojis: [],
                        identityContext: viewModel.identityContext)

                    fieldView.valueTextView.delegate = self

                    fieldsStackView.addArrangedSubview(fieldView)
                }

                for field in accountViewModel.fields {
                    let fieldView = AccountFieldView(
                        name: field.name,
                        value: field.value.attributed,
                        verifiedAt: field.verifiedAt,
                        emojis: accountViewModel.emojis,
                        identityContext: viewModel.identityContext)

                    fieldView.valueTextView.delegate = self

                    fieldsStackView.addArrangedSubview(fieldView)
                }

                fieldsStackView.isHidden = accountViewModel.fields.isEmpty && accountViewModel.identityProofs.isEmpty

                let noteFont = UIFont.preferredFont(forTextStyle: .callout)
                let mutableNote = NSMutableAttributedString(attributedString: accountViewModel.note)
                let noteRange = NSRange(location: 0, length: mutableNote.length)
                mutableNote.removeAttribute(.font, range: noteRange)
                mutableNote.addAttributes(
                    [.font: noteFont as Any,
                     .foregroundColor: UIColor.label],
                    range: noteRange)
                mutableNote.insert(emojis: accountViewModel.emojis,
                                   view: noteTextView,
                                   identityContext: viewModel.identityContext)
                mutableNote.resizeAttachments(toLineHeight: noteFont.lineHeight)
                noteTextView.attributedText = mutableNote
                noteTextView.isHidden = false

                followingButton.setAttributedLocalizedTitle(
                    localizationKey: "account.following-count",
                    count: accountViewModel.followingCount)
                followersButton.setAttributedLocalizedTitle(
                    localizationKey: "account.followers-count",
                    count: accountViewModel.followersCount)
                followStackView.isHidden = false
            } else {
                noteTextView.isHidden = true
                followStackView.isHidden = true
            }
        }
    }

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel

        // Initial size is to avoid unsatisfiable constraint warning
        super.init(frame: .init(origin: .zero, size: .init(width: 300, height: 300)))

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let pointSize = followingButton.titleLabel?.font.pointSize {
            relationshipButtonsStackView.heightAnchor
                .constraint(equalToConstant: pointSize + .defaultSpacing * 2).isActive = true
        }

        for button in [followButton, unfollowButton] {
            let inset = (button.bounds.height - (button.titleLabel?.bounds.height ?? 0))

            button.contentEdgeInsets = .init(top: 0, left: inset, bottom: 0, right: inset)
        }

        for button in [directMessageButton, followButton, unfollowButton, notifyButton, unnotifyButton] {
            button.layer.cornerRadius = button.bounds.height / 2
        }
    }
}

extension AccountHeaderView: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            viewModel.accountViewModel?.urlSelected(URL)
            return false
        case .preview: return false
        case .presentActions: return false
        @unknown default: return false
        }
    }
}

private extension AccountHeaderView {
    static let avatarDimension = CGFloat.avatarDimension * 2
    static let missingHeaderImageSize = CGSize(width: 1, height: 1)
    static let joinedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.dateStyle = .short

        return formatter
    }()

    // swiftlint:disable:next function_body_length
    func initialSetup() {
        let baseStackView = UIStackView()

        addSubview(headerImageBackgroundView)
        headerImageBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        headerImageBackgroundView.backgroundColor = .secondarySystemBackground

        addSubview(headerImageView)
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        headerImageView.isUserInteractionEnabled = true

        headerImageView.addSubview(headerButton)
        headerButton.translatesAutoresizingMaskIntoConstraints = false
        headerButton.setBackgroundImage(.highlightedButtonBackground, for: .highlighted)

        headerButton.addAction(UIAction { [weak self] _ in self?.viewModel.presentHeader() }, for: .touchUpInside)
        headerButton.isEnabled = false

        let avatarBackgroundViewDimension = Self.avatarDimension + .compactSpacing * 2

        addSubview(avatarBackgroundView)
        avatarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        avatarBackgroundView.backgroundColor = .systemBackground
        avatarBackgroundView.layer.cornerRadius = avatarBackgroundViewDimension / 2

        avatarBackgroundView.addSubview(avatarImageView)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.layer.cornerRadius = Self.avatarDimension / 2

        avatarImageView.addSubview(avatarButton)
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.setBackgroundImage(.highlightedButtonBackground, for: .highlighted)

        avatarButton.addAction(UIAction { [weak self] _ in self?.viewModel.presentAvatar() }, for: .touchUpInside)

        addSubview(relationshipButtonsStackView)
        relationshipButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
        relationshipButtonsStackView.spacing = .defaultSpacing
        relationshipButtonsStackView.addArrangedSubview(UIView())

        for button in [directMessageButton, notifyButton, unnotifyButton, followButton, unfollowButton] {
            relationshipButtonsStackView.addArrangedSubview(button)
            button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.backgroundColor = .secondarySystemBackground
        }

        directMessageButton.setImage(
            UIImage(
                systemName: "envelope",
                withConfiguration: UIImage.SymbolConfiguration(scale: .small)),
            for: .normal)
        directMessageButton.accessibilityLabel = NSLocalizedString("account.direct-message", comment: "")
        directMessageButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.sendDirectMessage() },
            for: .touchUpInside)

        followButton.setImage(
            UIImage(
                systemName: "person.badge.plus",
                withConfiguration: UIImage.SymbolConfiguration(scale: .small)),
            for: .normal)
        followButton.isHidden = true
        followButton.titleLabel?.adjustsFontSizeToFitWidth = true
        followButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.accountViewModel?.follow() },
            for: .touchUpInside)

        unfollowButton.setImage(
            UIImage(
                systemName: "checkmark",
                withConfiguration: UIImage.SymbolConfiguration(scale: .small)),
            for: .normal)
        unfollowButton.setTitle(NSLocalizedString("account.following", comment: ""), for: .normal)
        unfollowButton.isHidden = true
        unfollowButton.titleLabel?.adjustsFontSizeToFitWidth = true
        unfollowButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.accountViewModel?.confirmUnfollow() },
            for: .touchUpInside)

        notifyButton.setImage(
            UIImage(systemName: "bell",
                    withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .normal)
        notifyButton.imageView?.contentMode = .scaleAspectFit
        notifyButton.accessibilityLabel = NSLocalizedString("account.notify", comment: "")
        notifyButton.tintColor = .secondaryLabel
        notifyButton.isHidden = true
        notifyButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.accountViewModel?.notify() },
            for: .touchUpInside)

        unnotifyButton.setImage(
            UIImage(systemName: "bell.fill",
                    withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .normal)
        unnotifyButton.accessibilityLabel = NSLocalizedString("account.unnotify", comment: "")
        unnotifyButton.isHidden = true
        unnotifyButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.accountViewModel?.unnotify() },
            for: .touchUpInside)

        addSubview(baseStackView)
        baseStackView.translatesAutoresizingMaskIntoConstraints = false
        baseStackView.axis = .vertical
        baseStackView.spacing = .defaultSpacing

        baseStackView.addArrangedSubview(displayNameLabel)
        displayNameLabel.numberOfLines = 0
        displayNameLabel.font = .preferredFont(forTextStyle: .headline)
        displayNameLabel.adjustsFontForContentSizeCategory = true

        baseStackView.addArrangedSubview(accountStackView)
        accountStackView.spacing = .compactSpacing
        accountStackView.isAccessibilityElement = true

        accountStackView.addArrangedSubview(accountLabel)
        accountLabel.numberOfLines = 0
        accountLabel.font = .preferredFont(forTextStyle: .subheadline)
        accountLabel.adjustsFontForContentSizeCategory = true
        accountLabel.textColor = .secondaryLabel
        accountLabel.setContentHuggingPriority(.required, for: .horizontal)
        accountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        accountStackView.addArrangedSubview(lockedImageView)
        lockedImageView.image = UIImage(
            systemName: "lock.fill",
            withConfiguration: UIImage.SymbolConfiguration(scale: .small))
        lockedImageView.tintColor = .secondaryLabel
        lockedImageView.contentMode = .scaleAspectFit

        accountStackView.addArrangedSubview(followsYouLabel)
        followsYouLabel.text = NSLocalizedString("account.follows-you", comment: "")
        followsYouLabel.isHidden = true

        accountStackView.addArrangedSubview(mutedLabel)
        mutedLabel.text = NSLocalizedString("account.muted", comment: "")
        mutedLabel.isHidden = true

        accountStackView.addArrangedSubview(blockedLabel)
        blockedLabel.text = NSLocalizedString("account.blocked", comment: "")
        blockedLabel.isHidden = true

        accountStackView.addArrangedSubview(UIView())

        baseStackView.addArrangedSubview(statusCountJoinedStackView)
        statusCountJoinedStackView.spacing = .compactSpacing

        statusCountJoinedStackView.addArrangedSubview(statusCountLabel)
        statusCountLabel.font = .preferredFont(forTextStyle: .footnote)
        statusCountLabel.adjustsFontForContentSizeCategory = true
        statusCountLabel.textColor = .tertiaryLabel
        statusCountLabel.setContentHuggingPriority(.required, for: .horizontal)
        statusCountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        statusCountJoinedStackView.addArrangedSubview(statusCountJoinedSeparatorLabel)
        statusCountJoinedSeparatorLabel.font = .preferredFont(forTextStyle: .footnote)
        statusCountJoinedSeparatorLabel.adjustsFontForContentSizeCategory = true
        statusCountJoinedSeparatorLabel.textColor = .tertiaryLabel
        statusCountJoinedSeparatorLabel.setContentHuggingPriority(.required, for: .horizontal)
        statusCountJoinedSeparatorLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusCountJoinedSeparatorLabel.text = "•"
        statusCountJoinedSeparatorLabel.isAccessibilityElement = false

        statusCountJoinedStackView.addArrangedSubview(joinedLabel)
        joinedLabel.font = .preferredFont(forTextStyle: .footnote)
        joinedLabel.adjustsFontForContentSizeCategory = true
        joinedLabel.textColor = .tertiaryLabel
        joinedLabel.setContentHuggingPriority(.required, for: .horizontal)
        joinedLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        statusCountJoinedStackView.addArrangedSubview(UIView())

        baseStackView.addArrangedSubview(fieldsStackView)
        fieldsStackView.axis = .vertical
        fieldsStackView.spacing = .hairline
        fieldsStackView.backgroundColor = .separator
        fieldsStackView.clipsToBounds = true
        fieldsStackView.layer.borderColor = UIColor.separator.cgColor
        fieldsStackView.layer.borderWidth = .hairline
        fieldsStackView.layer.cornerRadius = .defaultCornerRadius
        fieldsStackView.isHidden = true

        baseStackView.addArrangedSubview(noteTextView)
        noteTextView.delegate = self

        baseStackView.addArrangedSubview(followStackView)
        followStackView.distribution = .fillEqually

        followingButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.accountViewModel?.followingSelected() },
            for: .touchUpInside)
        followStackView.addArrangedSubview(followingButton)

        followersButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.accountViewModel?.followersSelected() },
            for: .touchUpInside)
        followStackView.addArrangedSubview(followersButton)

        let statusWord = viewModel.identityContext.appPreferences.statusWord

        for (index, collection) in ProfileCollection.allCases.enumerated() {
            segmentedControl.insertSegment(
                action: UIAction(title: collection.title(statusWord: statusWord)) { [weak self] _ in
                    self?.viewModel.collection = collection
                    self?.viewModel.request(maxId: nil, minId: nil, search: nil)
                },
                at: index,
                animated: false)
        }

        segmentedControl.selectedSegmentIndex = 0

        baseStackView.addArrangedSubview(segmentedControl)

        baseStackView.addArrangedSubview(unavailableLabel)
        unavailableLabel.adjustsFontForContentSizeCategory = true
        unavailableLabel.font = .preferredFont(forTextStyle: .title3)
        unavailableLabel.textAlignment = .center
        unavailableLabel.numberOfLines = 0
        unavailableLabel.text = NSLocalizedString("account.unavailable", comment: "")
        unavailableLabel.isHidden = true

        let headerImageAspectRatioConstraint = headerImageView.heightAnchor.constraint(
            equalTo: headerImageView.widthAnchor,
            multiplier: 1 / 3)

        headerImageAspectRatioConstraint.priority = .justBelowMax

        NSLayoutConstraint.activate([
            headerImageAspectRatioConstraint,
            headerImageView.topAnchor.constraint(equalTo: topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerImageBackgroundView.leadingAnchor.constraint(equalTo: headerImageView.leadingAnchor),
            headerImageBackgroundView.topAnchor.constraint(equalTo: headerImageView.topAnchor),
            headerImageBackgroundView.trailingAnchor.constraint(equalTo: headerImageView.trailingAnchor),
            headerImageBackgroundView.bottomAnchor.constraint(equalTo: headerImageView.bottomAnchor),
            headerButton.leadingAnchor.constraint(equalTo: headerImageView.leadingAnchor),
            headerButton.topAnchor.constraint(equalTo: headerImageView.topAnchor),
            headerButton.bottomAnchor.constraint(equalTo: headerImageView.bottomAnchor),
            headerButton.trailingAnchor.constraint(equalTo: headerImageView.trailingAnchor),
            avatarBackgroundView.heightAnchor.constraint(equalToConstant: avatarBackgroundViewDimension),
            avatarBackgroundView.widthAnchor.constraint(equalToConstant: avatarBackgroundViewDimension),
            avatarBackgroundView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            avatarBackgroundView.centerYAnchor.constraint(equalTo: headerImageView.bottomAnchor),
            avatarImageView.heightAnchor.constraint(equalToConstant: Self.avatarDimension),
            avatarImageView.widthAnchor.constraint(equalToConstant: Self.avatarDimension),
            avatarImageView.centerXAnchor.constraint(equalTo: avatarBackgroundView.centerXAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: avatarBackgroundView.centerYAnchor),
            avatarButton.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            avatarButton.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            avatarButton.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            avatarButton.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            relationshipButtonsStackView.leadingAnchor.constraint(equalTo: avatarBackgroundView.trailingAnchor),
            relationshipButtonsStackView.topAnchor.constraint(
                equalTo: headerImageView.bottomAnchor,
                constant: .defaultSpacing),
            relationshipButtonsStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            directMessageButton.widthAnchor.constraint(equalTo: directMessageButton.heightAnchor),
            notifyButton.widthAnchor.constraint(equalTo: notifyButton.heightAnchor),
            unnotifyButton.widthAnchor.constraint(equalTo: unnotifyButton.heightAnchor),
            baseStackView.topAnchor.constraint(equalTo: avatarBackgroundView.bottomAnchor, constant: .defaultSpacing),
            baseStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            baseStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            baseStackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor)
        ])
    }
}
