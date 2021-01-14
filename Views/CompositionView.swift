// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Kingfisher
import UIKit
import ViewModels

final class CompositionView: UIView {
    let avatarImageView = UIImageView()
    let spoilerTextField = UITextField()
    let textView = UITextView()
    let textViewPlaceholder = UILabel()
    let removeButton = UIButton(type: .close)
    let inReplyToView = UIView()
    let hasReplyFollowingView = UIView()
    let attachmentsView = AttachmentsView()
    let attachmentUploadView: AttachmentUploadView
    let pollView: CompositionPollView
    let markAttachmentsSensitiveView: MarkAttachmentsSensitiveView

    private let viewModel: CompositionViewModel
    private let parentViewModel: NewStatusViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: CompositionViewModel, parentViewModel: NewStatusViewModel) {
        self.viewModel = viewModel
        self.parentViewModel = parentViewModel

        attachmentUploadView = AttachmentUploadView(viewModel: viewModel)
        markAttachmentsSensitiveView = MarkAttachmentsSensitiveView(viewModel: viewModel)
        pollView = CompositionPollView(viewModel: viewModel, parentViewModel: parentViewModel)

        super.init(frame: .zero)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CompositionView {
    var id: CompositionViewModel.Id { viewModel.id }
}

extension CompositionView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        viewModel.text = textView.text
    }
}

private extension CompositionView {
    static let attachmentCollectionViewHeight: CGFloat = 200

    // swiftlint:disable:next function_body_length
    func initialSetup() {
        tag = viewModel.id.hashValue

        addSubview(avatarImageView)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.layer.cornerRadius = .avatarDimension / 2
        avatarImageView.clipsToBounds = true
        avatarImageView.setContentHuggingPriority(.required, for: .horizontal)

        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .defaultSpacing

        let spoilerTextinputAccessoryView = CompositionInputAccessoryView(
            viewModel: viewModel,
            parentViewModel: parentViewModel)

        stackView.addArrangedSubview(spoilerTextField)
        spoilerTextField.borderStyle = .roundedRect
        spoilerTextField.adjustsFontForContentSizeCategory = true
        spoilerTextField.font = .preferredFont(forTextStyle: .body)
        spoilerTextField.placeholder = NSLocalizedString("status.spoiler-text-placeholder", comment: "")
        spoilerTextField.inputAccessoryView = spoilerTextinputAccessoryView
        spoilerTextField.tag = spoilerTextinputAccessoryView.tagForInputView
        spoilerTextField.addAction(
            UIAction { [weak self] _ in
                guard let self = self, let text = self.spoilerTextField.text else { return }

                self.viewModel.contentWarning = text
            },
            for: .editingChanged)

        let textViewFont = UIFont.preferredFont(forTextStyle: .body)
        let textInputAccessoryView = CompositionInputAccessoryView(
            viewModel: viewModel,
            parentViewModel: parentViewModel)

        stackView.addArrangedSubview(textView)
        textView.isScrollEnabled = false
        textView.adjustsFontForContentSizeCategory = true
        textView.font = textViewFont
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.inputAccessoryView = textInputAccessoryView
        textView.tag = textInputAccessoryView.tagForInputView
        textView.inputAccessoryView?.sizeToFit()
        textView.delegate = self

        textView.addSubview(textViewPlaceholder)
        textViewPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        textViewPlaceholder.adjustsFontForContentSizeCategory = true
        textViewPlaceholder.font = .preferredFont(forTextStyle: .body)
        textViewPlaceholder.textColor = .secondaryLabel
        textViewPlaceholder.text = NSLocalizedString("compose.prompt", comment: "")

        stackView.addArrangedSubview(attachmentsView)
        attachmentsView.isHidden = true
        stackView.addArrangedSubview(attachmentUploadView)
        attachmentUploadView.isHidden = true
        stackView.addArrangedSubview(markAttachmentsSensitiveView)
        markAttachmentsSensitiveView.isHidden = true
        stackView.addArrangedSubview(pollView)
        pollView.isHidden = true

        addSubview(removeButton)
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.showsMenuAsPrimaryAction = true
        removeButton.menu = UIMenu(
            children: [
                UIAction(
                    title: NSLocalizedString("remove", comment: ""),
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive) { [weak self] _ in
                    guard let self = self else { return }

                    self.parentViewModel.remove(viewModel: self.viewModel)
                }])
        removeButton.setContentHuggingPriority(.required, for: .horizontal)
        removeButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        for view in [inReplyToView, hasReplyFollowingView] {
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .opaqueSeparator
            view.widthAnchor.constraint(equalToConstant: .hairline).isActive = true
        }

        textView.text = viewModel.text
        spoilerTextField.text = viewModel.contentWarning

        let textViewBaselineConstraint = textView.topAnchor.constraint(
            lessThanOrEqualTo: avatarImageView.centerYAnchor,
            constant: -textViewFont.lineHeight / 2)

        viewModel.$text.map(\.isEmpty)
            .sink { [weak self] in self?.textViewPlaceholder.isHidden = !$0 }
            .store(in: &cancellables)

        viewModel.$displayContentWarning
            .sink { [weak self] in
                guard let self = self else { return }

                if self.spoilerTextField.isHidden && self.textView.isFirstResponder && $0 {
                    self.spoilerTextField.becomeFirstResponder()
                } else if !self.spoilerTextField.isHidden && self.spoilerTextField.isFirstResponder && !$0 {
                    self.textView.becomeFirstResponder()
                }

                self.spoilerTextField.isHidden = !$0
                textViewBaselineConstraint.isActive = !$0
            }
            .store(in: &cancellables)

        parentViewModel.$identification.map(\.identity.image)
            .sink { [weak self] in self?.avatarImageView.kf.setImage(with: $0) }
            .store(in: &cancellables)

        viewModel.$attachmentViewModels
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.attachmentsView.viewModel = self?.viewModel
                self?.attachmentsView.isHidden = $0.isEmpty
                self?.markAttachmentsSensitiveView.isHidden = $0.isEmpty
            }
            .store(in: &cancellables)

        viewModel.$displayPoll
            .sink { [weak self] in
                if !$0 {
                    self?.textView.becomeFirstResponder()
                }

                self?.pollView.isHidden = !$0
            }
            .store(in: &cancellables)

        let guide = UIDevice.current.userInterfaceIdiom == .pad ? readableContentGuide : layoutMarginsGuide
        let constraints = [
            avatarImageView.heightAnchor.constraint(equalToConstant: .avatarDimension),
            avatarImageView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            avatarImageView.topAnchor.constraint(equalTo: guide.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: guide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: .defaultSpacing),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: guide.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: guide.bottomAnchor),
            textViewPlaceholder.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            textViewPlaceholder.topAnchor.constraint(equalTo: textView.topAnchor),
            textViewPlaceholder.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            removeButton.leadingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: .defaultSpacing),
            removeButton.topAnchor.constraint(equalTo: guide.topAnchor),
            removeButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            inReplyToView.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            inReplyToView.topAnchor.constraint(equalTo: topAnchor),
            inReplyToView.bottomAnchor.constraint(equalTo: avatarImageView.topAnchor),
            hasReplyFollowingView.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            hasReplyFollowingView.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            hasReplyFollowingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
