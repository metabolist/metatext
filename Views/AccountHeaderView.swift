// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import UIKit
import ViewModels

final class AccountHeaderView: UIView {
    let headerImageView = AnimatedImageView()
    let headerButton = UIButton()
    let noteTextView = TouchFallthroughTextView()
    let segmentedControl = UISegmentedControl()

    var viewModel: ProfileViewModel? {
        didSet {
            if let accountViewModel = viewModel?.accountViewModel {
                headerImageView.kf.setImage(with: accountViewModel.headerURL)
                headerImageView.tag = accountViewModel.headerURL.hashValue

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

        headerButton.addAction(
            UIAction { [weak self] _ in self?.viewModel?.presentHeader() },
            for: .touchUpInside)

        addSubview(baseStackView)
        baseStackView.translatesAutoresizingMaskIntoConstraints = false
        baseStackView.axis = .vertical

        noteTextView.isScrollEnabled = false
        noteTextView.delegate = self
        baseStackView.addArrangedSubview(noteTextView)

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
            baseStackView.topAnchor.constraint(equalTo: headerImageView.bottomAnchor),
            baseStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            baseStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            baseStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
