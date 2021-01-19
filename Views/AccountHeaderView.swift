// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import UIKit
import ViewModels

final class AccountHeaderView: UIView {
    let headerImageBackgroundView = UIView()
    let headerImageView = AnimatedImageView()
    let headerButton = UIButton()
    let avatarBackgroundView = UIView()
    let avatarImageView = UIImageView()
    let avatarButton = UIButton()
    let relationshipButtonsStackView = UIStackView()
    let followButton = UIButton(type: .system)
    let unfollowButton = UIButton(type: .system)
    let displayNameLabel = UILabel()
    let accountStackView = UIStackView()
    let accountLabel = UILabel()
    let lockedImageView = UIImageView()
    let fieldsStackView = UIStackView()
    let noteTextView = TouchFallthroughTextView()
    let followStackView = UIStackView()
    let followingButton = UIButton()
    let followersButton = UIButton()
    let segmentedControl = UISegmentedControl()

    var viewModel: ProfileViewModel? {
        didSet {
            if let accountViewModel = viewModel?.accountViewModel {
                headerImageView.kf.setImage(with: accountViewModel.headerURL) { [weak self] in
                    if case let .success(result) = $0, result.image.size != Self.missingHeaderImageSize {
                        self?.headerButton.isEnabled = true
                    }
                }
                headerImageView.tag = accountViewModel.headerURL.hashValue
                avatarImageView.kf.setImage(with: accountViewModel.avatarURL(profile: true))
                avatarImageView.tag = accountViewModel.avatarURL(profile: true).hashValue

                if !accountViewModel.isSelf, let relationship = accountViewModel.relationship {
                    followButton.setTitle(
                        NSLocalizedString(
                            accountViewModel.isLocked ? "account.request" : "account.follow",
                            comment: ""),
                        for: .normal)
                    followButton.isHidden = relationship.following
                    unfollowButton.isHidden = !relationship.following

                    relationshipButtonsStackView.isHidden = false
                } else {
                    relationshipButtonsStackView.isHidden = true
                }

                if accountViewModel.displayName.isEmpty {
                    displayNameLabel.isHidden = true
                } else {
                    let mutableDisplayName = NSMutableAttributedString(string: accountViewModel.displayName)

                    mutableDisplayName.insert(emojis: accountViewModel.emojis, view: displayNameLabel)
                    mutableDisplayName.resizeAttachments(toLineHeight: displayNameLabel.font.lineHeight)
                    displayNameLabel.attributedText = mutableDisplayName
                }

                accountLabel.text = accountViewModel.accountName
                lockedImageView.isHidden = !accountViewModel.isLocked

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
                        emojis: [])

                    fieldView.valueTextView.delegate = self

                    fieldsStackView.addArrangedSubview(fieldView)
                }

                for field in accountViewModel.fields {
                    let fieldView = AccountFieldView(
                        name: field.name,
                        value: field.value.attributed,
                        verifiedAt: field.verifiedAt,
                        emojis: accountViewModel.emojis)

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
                mutableNote.insert(emojis: accountViewModel.emojis, view: noteTextView)
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

    override init(frame: CGRect) {
        super.init(frame: frame)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        for button in [followButton, unfollowButton] {
            let inset = (followButton.bounds.height - (button.titleLabel?.bounds.height ?? 0)) / 2

            button.contentEdgeInsets = .init(top: 0, left: inset, bottom: 0, right: inset)
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
            viewModel?.accountViewModel?.urlSelected(URL)
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

        headerButton.addAction(UIAction { [weak self] _ in self?.viewModel?.presentHeader() }, for: .touchUpInside)
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

        avatarButton.addAction(UIAction { [weak self] _ in self?.viewModel?.presentAvatar() }, for: .touchUpInside)

        addSubview(relationshipButtonsStackView)
        relationshipButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
        relationshipButtonsStackView.spacing = .defaultSpacing
        relationshipButtonsStackView.addArrangedSubview(UIView())

        for button in [followButton, unfollowButton] {
            relationshipButtonsStackView.addArrangedSubview(button)
            button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.backgroundColor = .secondarySystemBackground
        }

        followButton.setImage(
            UIImage(
                systemName: "person.badge.plus",
                withConfiguration: UIImage.SymbolConfiguration(scale: .small)),
            for: .normal)
        followButton.addAction(
            UIAction { [weak self] _ in self?.viewModel?.accountViewModel?.follow() },
            for: .touchUpInside)

        unfollowButton.setImage(
            UIImage(
                systemName: "checkmark",
                withConfiguration: UIImage.SymbolConfiguration(scale: .small)),
            for: .normal)
        unfollowButton.setTitle(NSLocalizedString("account.following", comment: ""), for: .normal)
        unfollowButton.showsMenuAsPrimaryAction = true
        unfollowButton.menu = UIMenu(children: [UIDeferredMenuElement { [weak self] completion in
            guard let accountViewModel = self?.viewModel?.accountViewModel else { return }

            let unfollowAction = UIAction(
                title: NSLocalizedString("account.unfollow", comment: ""),
                image: UIImage(systemName: "person.badge.minus"),
                attributes: .destructive) { _ in
                accountViewModel.unfollow()
            }

            completion([unfollowAction])
        },
        UIAction(title: NSLocalizedString("cancel", comment: "")) { _ in }])

        addSubview(baseStackView)
        baseStackView.translatesAutoresizingMaskIntoConstraints = false
        baseStackView.axis = .vertical
        baseStackView.spacing = .defaultSpacing

        baseStackView.addArrangedSubview(displayNameLabel)
        displayNameLabel.numberOfLines = 0
        displayNameLabel.font = .preferredFont(forTextStyle: .headline)
        displayNameLabel.adjustsFontForContentSizeCategory = true

        baseStackView.addArrangedSubview(accountStackView)

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

        accountStackView.addArrangedSubview(UIView())

        baseStackView.addArrangedSubview(fieldsStackView)
        fieldsStackView.axis = .vertical
        fieldsStackView.spacing = .hairline
        fieldsStackView.backgroundColor = .separator
        fieldsStackView.clipsToBounds = true
        fieldsStackView.layer.borderColor = UIColor.separator.cgColor
        fieldsStackView.layer.borderWidth = .hairline
        fieldsStackView.layer.cornerRadius = .defaultCornerRadius

        baseStackView.addArrangedSubview(noteTextView)
        noteTextView.isScrollEnabled = false
        noteTextView.delegate = self

        baseStackView.addArrangedSubview(followStackView)
        followStackView.distribution = .fillEqually

        followingButton.addAction(
            UIAction { [weak self] _ in self?.viewModel?.accountViewModel?.followingSelected() },
            for: .touchUpInside)
        followStackView.addArrangedSubview(followingButton)

        followersButton.addAction(
            UIAction { [weak self] _ in self?.viewModel?.accountViewModel?.followersSelected() },
            for: .touchUpInside)
        followStackView.addArrangedSubview(followersButton)

        for (index, collection) in ProfileCollection.allCases.enumerated() {
            segmentedControl.insertSegment(
                action: UIAction(title: collection.title) { [weak self] _ in
                    self?.viewModel?.collection = collection
                    self?.viewModel?.request(maxId: nil, minId: nil)
                },
                at: index,
                animated: false)
        }

        segmentedControl.selectedSegmentIndex = 0

        baseStackView.addArrangedSubview(segmentedControl)

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
            relationshipButtonsStackView.bottomAnchor.constraint(equalTo: avatarBackgroundView.bottomAnchor),
            baseStackView.topAnchor.constraint(equalTo: avatarBackgroundView.bottomAnchor, constant: .defaultSpacing),
            baseStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            baseStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            baseStackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor)
        ])
    }
}
