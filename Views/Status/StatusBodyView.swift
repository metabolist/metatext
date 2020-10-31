// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class StatusBodyView: UIView {
    let spoilerTextLabel = UILabel()
    let toggleShowContentButton = UIButton(type: .system)
    let contentTextView = TouchFallthroughTextView()
    let attachmentsView = StatusAttachmentsView()
    let pollView = PollView()
    let cardView = CardView()

    var viewModel: StatusViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }

            let isContextParent = viewModel.configuration.isContextParent
            let mutableContent = NSMutableAttributedString(attributedString: viewModel.content)
            let mutableSpoilerText = NSMutableAttributedString(string: viewModel.spoilerText)
            let contentFont = UIFont.preferredFont(forTextStyle: isContextParent ? .title3 : .callout)
            let contentRange = NSRange(location: 0, length: mutableContent.length)

            contentTextView.shouldFallthrough = !isContextParent

            mutableContent.removeAttribute(.font, range: contentRange)
            mutableContent.addAttributes(
                [.font: contentFont, .foregroundColor: UIColor.label],
                range: contentRange)
            mutableContent.insert(emoji: viewModel.contentEmoji, view: contentTextView)
            mutableContent.resizeAttachments(toLineHeight: contentFont.lineHeight)
            contentTextView.attributedText = mutableContent
            contentTextView.isHidden = contentTextView.text == ""

            mutableSpoilerText.insert(emoji: viewModel.contentEmoji, view: spoilerTextLabel)
            mutableSpoilerText.resizeAttachments(toLineHeight: spoilerTextLabel.font.lineHeight)
            spoilerTextLabel.font = contentFont
            spoilerTextLabel.attributedText = mutableSpoilerText
            spoilerTextLabel.isHidden = spoilerTextLabel.text == ""
            toggleShowContentButton.setTitle(
                viewModel.shouldShowContent
                    ? NSLocalizedString("status.show-less", comment: "")
                    : NSLocalizedString("status.show-more", comment: ""),
                for: .normal)
            toggleShowContentButton.isHidden = viewModel.spoilerText == ""

            contentTextView.isHidden = !viewModel.shouldShowContent

            attachmentsView.isHidden = viewModel.attachmentViewModels.count == 0
            attachmentsView.viewModel = viewModel

            pollView.isHidden = viewModel.pollOptions.count == 0
            pollView.viewModel = viewModel

            cardView.viewModel = viewModel.cardViewModel
            cardView.isHidden = viewModel.cardViewModel == nil
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

extension StatusBodyView: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            viewModel?.urlSelected(URL)
            return false
        case .preview: return false
        case .presentActions: return false
        @unknown default: return false
        }
    }
}

private extension StatusBodyView {
    func initialSetup() {
        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .compactSpacing

        spoilerTextLabel.numberOfLines = 0
        spoilerTextLabel.adjustsFontForContentSizeCategory = true
        stackView.addArrangedSubview(spoilerTextLabel)

        toggleShowContentButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        toggleShowContentButton.titleLabel?.adjustsFontForContentSizeCategory = true
        toggleShowContentButton.addAction(
            UIAction { [weak self] _ in self?.viewModel?.toggleShowContent() },
            for: .touchUpInside)
        stackView.addArrangedSubview(toggleShowContentButton)

        contentTextView.adjustsFontForContentSizeCategory = true
        contentTextView.isScrollEnabled = false
        contentTextView.backgroundColor = .clear
        contentTextView.delegate = self
        stackView.addArrangedSubview(contentTextView)

        stackView.addArrangedSubview(attachmentsView)

        stackView.addArrangedSubview(pollView)

        cardView.button.addAction(
            UIAction { [weak self] _ in
                guard
                    let viewModel = self?.viewModel,
                    let url = viewModel.cardViewModel?.url
                else { return }

                viewModel.urlSelected(url)
            },
            for: .touchUpInside)
        stackView.addArrangedSubview(cardView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
