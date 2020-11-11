// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import UIKit
import ViewModels

final class AccountHeaderView: UIView {
    let headerImageView = AnimatedImageView()
    let headerButton = UIButton()
    let avatarImageView = UIImageView()
    let avatarButton = UIButton()
    let displayNameLabel = UILabel()
    let accountStackView = UIStackView()
    let accountLabel = UILabel()
    let lockedImageView = UIImageView()
    let fieldsStackView = UIStackView()
    let noteTextView = TouchFallthroughTextView()
    let segmentedControl = UISegmentedControl()

    var viewModel: ProfileViewModel? {
        didSet {
            if let accountViewModel = viewModel?.accountViewModel {
                headerImageView.kf.setImage(with: accountViewModel.headerURL)
                headerImageView.tag = accountViewModel.headerURL.hashValue
                avatarImageView.kf.setImage(with: accountViewModel.avatarURL(profile: true))
                avatarImageView.tag = accountViewModel.avatarURL(profile: true).hashValue

                if accountViewModel.displayName.isEmpty {
                    displayNameLabel.isHidden = true
                } else {
                    let mutableDisplayName = NSMutableAttributedString(string: accountViewModel.displayName)

                    mutableDisplayName.insert(emoji: accountViewModel.emoji, view: displayNameLabel)
                    mutableDisplayName.resizeAttachments(toLineHeight: displayNameLabel.font.lineHeight)
                    displayNameLabel.attributedText = mutableDisplayName
                }

                accountLabel.text = accountViewModel.accountName
                lockedImageView.isHidden = !accountViewModel.isLocked

                for view in fieldsStackView.arrangedSubviews {
                    fieldsStackView.removeArrangedSubview(view)
                    view.removeFromSuperview()
                }

                for field in accountViewModel.fields {
                    let fieldView = AccountFieldView(field: field, emoji: accountViewModel.emoji)

                    fieldView.valueTextView.delegate = self

                    fieldsStackView.addArrangedSubview(fieldView)
                }

                fieldsStackView.isHidden = accountViewModel.fields.isEmpty

                let noteFont = UIFont.preferredFont(forTextStyle: .callout)
                let mutableNote = NSMutableAttributedString(attributedString: accountViewModel.note)
                let noteRange = NSRange(location: 0, length: mutableNote.length)
                mutableNote.removeAttribute(.font, range: noteRange)
                mutableNote.addAttributes(
                    [.font: noteFont as Any,
                     .foregroundColor: UIColor.label],
                    range: noteRange)
                mutableNote.insert(emoji: accountViewModel.emoji, view: noteTextView)
                mutableNote.resizeAttachments(toLineHeight: noteFont.lineHeight)
                noteTextView.attributedText = mutableNote
                noteTextView.isHidden = false
            } else {
                noteTextView.isHidden = true
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

    // swiftlint:disable:next function_body_length
    func initialSetup() {
        let baseStackView = UIStackView()

        addSubview(headerImageView)
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        headerImageView.isUserInteractionEnabled = true

        headerImageView.addSubview(headerButton)
        headerButton.translatesAutoresizingMaskIntoConstraints = false
        headerButton.setBackgroundImage(.highlightedButtonBackground, for: .highlighted)

        headerButton.addAction(UIAction { [weak self] _ in self?.viewModel?.presentHeader() }, for: .touchUpInside)

        addSubview(avatarImageView)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.layer.cornerRadius = Self.avatarDimension / 2
        avatarImageView.layer.borderWidth = .compactSpacing
        avatarImageView.layer.borderColor = UIColor.systemBackground.cgColor

        avatarImageView.addSubview(avatarButton)
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.setBackgroundImage(.highlightedButtonBackground, for: .highlighted)

        avatarButton.addAction(UIAction { [weak self] _ in self?.viewModel?.presentAvatar() }, for: .touchUpInside)

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
            headerButton.leadingAnchor.constraint(equalTo: headerImageView.leadingAnchor),
            headerButton.topAnchor.constraint(equalTo: headerImageView.topAnchor),
            headerButton.bottomAnchor.constraint(equalTo: headerImageView.bottomAnchor),
            headerButton.trailingAnchor.constraint(equalTo: headerImageView.trailingAnchor),
            avatarImageView.heightAnchor.constraint(equalToConstant: Self.avatarDimension),
            avatarImageView.widthAnchor.constraint(equalToConstant: Self.avatarDimension),
            avatarImageView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: headerImageView.bottomAnchor),
            avatarButton.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            avatarButton.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            avatarButton.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            avatarButton.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            baseStackView.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: .defaultSpacing),
            baseStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            baseStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            baseStackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor)
        ])
    }
}
