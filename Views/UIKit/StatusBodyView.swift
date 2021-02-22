// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit
import ViewModels

final class StatusBodyView: UIView {
    let spoilerTextLabel = AnimatedAttachmentLabel()
    let toggleShowContentButton = CapsuleButton()
    let contentTextView = TouchFallthroughTextView()
    let attachmentsView = AttachmentsView()
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
            mutableContent.insert(emojis: viewModel.contentEmojis,
                                  view: contentTextView,
                                  identityContext: viewModel.identityContext)
            mutableContent.resizeAttachments(toLineHeight: contentFont.lineHeight)
            contentTextView.attributedText = mutableContent
            contentTextView.isHidden = contentTextView.text.isEmpty

            mutableSpoilerText.insert(emojis: viewModel.contentEmojis,
                                      view: spoilerTextLabel,
                                      identityContext: viewModel.identityContext)
            mutableSpoilerText.resizeAttachments(toLineHeight: spoilerTextLabel.font.lineHeight)
            spoilerTextLabel.font = contentFont
            spoilerTextLabel.attributedText = mutableSpoilerText
            spoilerTextLabel.isHidden = spoilerTextLabel.text == ""
            toggleShowContentButton.setTitle(
                viewModel.shouldShowContent
                    ? NSLocalizedString("status.show-less", comment: "")
                    : NSLocalizedString("status.show-more", comment: ""),
                for: .normal)
            toggleShowContentButton.isHidden = viewModel.spoilerText.isEmpty

            contentTextView.isHidden = !viewModel.shouldShowContent

            attachmentsView.isHidden = viewModel.attachmentViewModels.isEmpty
            attachmentsView.viewModel = viewModel

            pollView.isHidden = viewModel.pollOptions.isEmpty || !viewModel.shouldShowContent
            pollView.viewModel = viewModel
            pollView.isAccessibilityElement = !isContextParent || viewModel.hasVotedInPoll || viewModel.isPollExpired

            cardView.viewModel = viewModel.cardViewModel
            cardView.isHidden = viewModel.cardViewModel == nil

            let accessibilityAttributedLabel = NSMutableAttributedString(string: "")

            if !spoilerTextLabel.isHidden {
                accessibilityAttributedLabel.append(mutableSpoilerText)
            }

            if !toggleShowContentButton.isHidden {
                accessibilityAttributedLabel.appendWithSeparator(
                    NSLocalizedString("status.content-warning.accessibility", comment: ""))

                if viewModel.shouldShowContent {
                    accessibilityAttributedLabel.appendWithSeparator(
                        NSLocalizedString("status.content-warning.accessibility.opened", comment: ""))
                } else {
                    accessibilityAttributedLabel.appendWithSeparator(
                        NSLocalizedString("status.content-warning.accessibility.closed", comment: ""))
                }
            }

            if !contentTextView.isHidden {
                if spoilerTextLabel.isHidden {
                    accessibilityAttributedLabel.append(mutableContent)
                } else {
                    accessibilityAttributedLabel.appendWithSeparator(mutableContent)
                }
            }

            for view in [attachmentsView, pollView, cardView] where !view.isHidden {
                guard let viewAccessibilityLabel = view.accessibilityLabel else { continue }

                accessibilityAttributedLabel.appendWithSeparator(viewAccessibilityLabel)
            }

            self.accessibilityAttributedLabel = accessibilityAttributedLabel

            var accessibilityCustomActions = [UIAccessibilityCustomAction]()

            mutableContent.enumerateAttribute(
                .link,
                in: NSRange(location: 0, length: mutableContent.length),
                options: []) { attribute, range, _ in
                guard let url = attribute as? URL else { return }

                accessibilityCustomActions.append(
                    UIAccessibilityCustomAction(
                        name: String.localizedStringWithFormat(
                            NSLocalizedString("accessibility.activate-link-%@", comment: ""),
                            mutableContent.attributedSubstring(from: range).string)) { [weak self] _ in
                        guard let contentTextView = self?.contentTextView else { return false }

                        _ = contentTextView.delegate?.textView?(
                            contentTextView,
                            shouldInteractWith: url,
                            in: range,
                            interaction: .invokeDefaultAction)

                        return true
                    })
            }

            self.accessibilityCustomActions = accessibilityCustomActions
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

extension StatusBodyView {
    static func estimatedHeight(width: CGFloat,
                                identityContext: IdentityContext,
                                status: Status,
                                configuration: CollectionItem.StatusConfiguration) -> CGFloat {
        let contentFont = UIFont.preferredFont(forTextStyle: configuration.isContextParent ? .title3 : .callout)
        var height: CGFloat = 0

        var contentHeight = status.displayStatus.content.attributed.string.height(
            width: width,
            font: contentFont)

        if status.displayStatus.card != nil {
            contentHeight += .compactSpacing
            contentHeight += CardView.estimatedHeight(
                width: width,
                identityContext: identityContext,
                status: status,
                configuration: configuration)
        }

        if status.displayStatus.poll != nil {
            contentHeight += .defaultSpacing
            contentHeight += PollView.estimatedHeight(
                width: width,
                identityContext: identityContext,
                status: status,
                configuration: configuration)
        }

        if status.displayStatus.spoilerText.isEmpty {
            height += contentHeight
        } else {
            height += status.displayStatus.spoilerText.height(width: width, font: contentFont)
            height += .compactSpacing
            height += NSLocalizedString("status.show-more", comment: "").height(
                width: width,
                font: .preferredFont(forTextStyle: .headline))

            if configuration.showContentToggled && !identityContext.identity.preferences.readingExpandSpoilers {
                height += .compactSpacing
                height += contentHeight
            }
        }

        if !status.displayStatus.mediaAttachments.isEmpty {
            height += .compactSpacing
            height += AttachmentsView.estimatedHeight(
                width: width,
                identityContext: identityContext,
                status: status,
                configuration: configuration)
        }

        return height
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
        stackView.spacing = .defaultSpacing

        spoilerTextLabel.numberOfLines = 0
        spoilerTextLabel.adjustsFontForContentSizeCategory = true
        stackView.addArrangedSubview(spoilerTextLabel)

        toggleShowContentButton.addAction(
            UIAction { [weak self] _ in self?.viewModel?.toggleShowContent() },
            for: .touchUpInside)
        stackView.addArrangedSubview(toggleShowContentButton)

        contentTextView.adjustsFontForContentSizeCategory = true
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
