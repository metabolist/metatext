// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import Mastodon
import UIKit
import ViewModels

final class AccountView: UIView {
    let avatarImageView = AnimatedImageView()
    let displayNameLabel = UILabel()
    let accountLabel = UILabel()
    let noteTextView = TouchFallthroughTextView()
    let acceptFollowRequestButton = UIButton()
    let rejectFollowRequestButton = UIButton()

    private var accountConfiguration: AccountContentConfiguration

    init(configuration: AccountContentConfiguration) {
        self.accountConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyAccountConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AccountView {
    static func estimatedHeight(width: CGFloat,
                                account: Account,
                                configuration: CollectionItem.AccountConfiguration) -> CGFloat {
        var height = CGFloat.defaultSpacing * 2
            + .compactSpacing
            + account.displayName.height(width: width, font: .preferredFont(forTextStyle: .headline))
            + account.acct.height(width: width, font: .preferredFont(forTextStyle: .subheadline))

        if configuration == .withNote {
            height += .compactSpacing + account.note.attributed.string.height(
                width: width,
                font: .preferredFont(forTextStyle: .callout))
        }

        return max(height, .avatarDimension + .defaultSpacing * 2)
    }
}

extension AccountView: UIContentView {
    var configuration: UIContentConfiguration {
        get { accountConfiguration }
        set {
            guard let accountConfiguration = newValue as? AccountContentConfiguration else { return }

            self.accountConfiguration = accountConfiguration

            applyAccountConfiguration()
        }
    }
}

extension AccountView: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            accountConfiguration.viewModel.urlSelected(URL)
            return false
        case .preview: return false
        case .presentActions: return false
        @unknown default: return false
        }
    }
}

private extension AccountView {
    func initialSetup() {
        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = .defaultSpacing
        stackView.alignment = .top

        stackView.addArrangedSubview(avatarImageView)
        avatarImageView.layer.cornerRadius = .avatarDimension / 2
        avatarImageView.clipsToBounds = true

        let verticalStackView = UIStackView()

        stackView.addArrangedSubview(verticalStackView)
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.axis = .vertical
        verticalStackView.spacing = .compactSpacing
        verticalStackView.addArrangedSubview(displayNameLabel)
        verticalStackView.addArrangedSubview(accountLabel)
        verticalStackView.addArrangedSubview(noteTextView)
        displayNameLabel.numberOfLines = 0
        displayNameLabel.font = .preferredFont(forTextStyle: .headline)
        displayNameLabel.adjustsFontForContentSizeCategory = true
        accountLabel.numberOfLines = 0
        accountLabel.font = .preferredFont(forTextStyle: .subheadline)
        accountLabel.adjustsFontForContentSizeCategory = true
        accountLabel.textColor = .secondaryLabel
        noteTextView.backgroundColor = .clear
        noteTextView.delegate = self

        let largeTitlePointSize = UIFont.preferredFont(forTextStyle: .largeTitle).pointSize

        stackView.addArrangedSubview(acceptFollowRequestButton)
        acceptFollowRequestButton.setImage(
            UIImage(systemName: "checkmark.circle",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: largeTitlePointSize)),
            for: .normal)
        acceptFollowRequestButton.setContentHuggingPriority(.required, for: .horizontal)
        acceptFollowRequestButton.addAction(
            UIAction { [weak self] _ in self?.accountConfiguration.viewModel.acceptFollowRequest() },
            for: .touchUpInside)

        stackView.addArrangedSubview(rejectFollowRequestButton)
        rejectFollowRequestButton.setImage(
            UIImage(systemName: "xmark.circle",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: largeTitlePointSize)),
            for: .normal)
        rejectFollowRequestButton.tintColor = .systemRed
        rejectFollowRequestButton.setContentHuggingPriority(.required, for: .horizontal)
        rejectFollowRequestButton.addAction(
            UIAction { [weak self] _ in self?.accountConfiguration.viewModel.rejectFollowRequest() },
            for: .touchUpInside)

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            avatarImageView.heightAnchor.constraint(equalToConstant: .avatarDimension),
            acceptFollowRequestButton.widthAnchor.constraint(greaterThanOrEqualToConstant: .avatarDimension),
            acceptFollowRequestButton.heightAnchor.constraint(greaterThanOrEqualToConstant: .avatarDimension),
            rejectFollowRequestButton.widthAnchor.constraint(greaterThanOrEqualToConstant: .avatarDimension),
            rejectFollowRequestButton.heightAnchor.constraint(greaterThanOrEqualToConstant: .avatarDimension),
            stackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor)
        ])
    }

    func applyAccountConfiguration() {
        let viewModel = accountConfiguration.viewModel

        avatarImageView.kf.setImage(with: viewModel.avatarURL(profile: false))

        if viewModel.displayName.isEmpty {
            displayNameLabel.isHidden = true
        } else {
            let mutableDisplayName = NSMutableAttributedString(string: viewModel.displayName)

            mutableDisplayName.insert(emojis: viewModel.emojis, view: displayNameLabel)
            mutableDisplayName.resizeAttachments(toLineHeight: displayNameLabel.font.lineHeight)
            displayNameLabel.attributedText = mutableDisplayName
        }

        accountLabel.text = viewModel.accountName

        if viewModel.configuration == .withNote {
            let noteFont = UIFont.preferredFont(forTextStyle: .callout)
            let mutableNote = NSMutableAttributedString(attributedString: viewModel.note)
            let noteRange = NSRange(location: 0, length: mutableNote.length)

            mutableNote.removeAttribute(.font, range: noteRange)
            mutableNote.addAttributes(
                [.font: noteFont as Any,
                 .foregroundColor: UIColor.label],
                range: noteRange)
            mutableNote.insert(emojis: viewModel.emojis, view: noteTextView)
            mutableNote.resizeAttachments(toLineHeight: noteFont.lineHeight)

            noteTextView.attributedText = mutableNote
            noteTextView.isHidden = false
        } else {
            noteTextView.isHidden = true
        }

        let isFollowRequest = viewModel.configuration == .followRequest

        acceptFollowRequestButton.isHidden = !isFollowRequest
        rejectFollowRequestButton.isHidden = !isFollowRequest
    }
}
