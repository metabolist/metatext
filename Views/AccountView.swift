// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import UIKit

class AccountView: UIView {
    let avatarImageView = AnimatedImageView()
    let displayNameLabel = UILabel()
    let accountLabel = UILabel()
    let noteTextView = TouchFallthroughTextView()

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

        addSubview(avatarImageView)
        addSubview(stackView)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.layer.cornerRadius = .avatarDimension / 2
        avatarImageView.clipsToBounds = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .compactSpacing
        stackView.addArrangedSubview(displayNameLabel)
        stackView.addArrangedSubview(accountLabel)
        stackView.addArrangedSubview(noteTextView)
        displayNameLabel.numberOfLines = 0
        displayNameLabel.font = .preferredFont(forTextStyle: .headline)
        displayNameLabel.adjustsFontForContentSizeCategory = true
        accountLabel.numberOfLines = 0
        accountLabel.font = .preferredFont(forTextStyle: .subheadline)
        accountLabel.adjustsFontForContentSizeCategory = true
        accountLabel.textColor = .secondaryLabel
        noteTextView.isScrollEnabled = false
        noteTextView.backgroundColor = .clear
        noteTextView.delegate = self

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            avatarImageView.heightAnchor.constraint(equalToConstant: .avatarDimension),
            avatarImageView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: readableContentGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: .defaultSpacing),
            stackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor)
        ])
    }

    func applyAccountConfiguration() {
        avatarImageView.kf.setImage(with: accountConfiguration.viewModel.avatarURL(profile: false))

        if accountConfiguration.viewModel.displayName == "" {
            displayNameLabel.isHidden = true
        } else {
            let mutableDisplayName = NSMutableAttributedString(string: accountConfiguration.viewModel.displayName)

            mutableDisplayName.insert(emoji: accountConfiguration.viewModel.emoji, view: displayNameLabel)
            mutableDisplayName.resizeAttachments(toLineHeight: displayNameLabel.font.lineHeight)
            displayNameLabel.attributedText = mutableDisplayName
        }

        accountLabel.text = accountConfiguration.viewModel.accountName

        let noteFont = UIFont.preferredFont(forTextStyle: .callout)
        let mutableNote = NSMutableAttributedString(attributedString: accountConfiguration.viewModel.note)
        let noteRange = NSRange(location: 0, length: mutableNote.length)

        mutableNote.removeAttribute(.font, range: noteRange)
        mutableNote.addAttributes(
            [.font: noteFont as Any,
             .foregroundColor: UIColor.label],
            range: noteRange)
        mutableNote.insert(emoji: accountConfiguration.viewModel.emoji, view: noteTextView)
        mutableNote.resizeAttachments(toLineHeight: noteFont.lineHeight)

        noteTextView.attributedText = mutableNote
    }
}
