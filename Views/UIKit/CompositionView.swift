// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Kingfisher
import UIKit
import ViewModels

final class CompositionView: UIView {
    let avatarImageView = AnimatedImageView()
    let changeIdentityButton = UIButton()
    let spoilerTextField = UITextField()
    let textView = ImagePastableTextView()
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

        if let textToSelectedRange = textView.textToSelectedRange {
            viewModel.textToSelectedRange = textToSelectedRange
        }
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

        changeIdentityButton.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.addSubview(changeIdentityButton)
        avatarImageView.isUserInteractionEnabled = true
        changeIdentityButton.setBackgroundImage(.highlightedButtonBackground, for: .highlighted)
        changeIdentityButton.showsMenuAsPrimaryAction = true
        changeIdentityButton.menu = changeIdentityMenu(identities: parentViewModel.authenticatedIdentities)

        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .defaultSpacing

        let spoilerTextinputAccessoryView = CompositionInputAccessoryView(
            viewModel: viewModel,
            parentViewModel: parentViewModel,
            autocompleteQueryPublisher: viewModel.$contentWarningAutocompleteQuery.eraseToAnyPublisher())

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

                if let textToSelectedRange = self.spoilerTextField.textToSelectedRange {
                    self.viewModel.contentWarningTextToSelectedRange = textToSelectedRange
                }
            },
            for: .editingChanged)

        let textViewFont = UIFont.preferredFont(forTextStyle: .body)
        let textInputAccessoryView = CompositionInputAccessoryView(
            viewModel: viewModel,
            parentViewModel: parentViewModel,
            autocompleteQueryPublisher: viewModel.$autocompleteQuery.eraseToAnyPublisher())

        stackView.addArrangedSubview(textView)
        textView.keyboardType = .twitter
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
        attachmentsView.isHidden_stackViewSafe = true
        stackView.addArrangedSubview(attachmentUploadView)
        attachmentUploadView.isHidden_stackViewSafe = true
        stackView.addArrangedSubview(markAttachmentsSensitiveView)
        markAttachmentsSensitiveView.isHidden_stackViewSafe = true
        stackView.addArrangedSubview(pollView)
        pollView.isHidden_stackViewSafe = true

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
            .sink { [weak self] in self?.textViewPlaceholder.isHidden_stackViewSafe = !$0 }
            .store(in: &cancellables)

        viewModel.$displayContentWarning
            .throttle(for: .seconds(TimeInterval.zeroIfReduceMotion(.shortAnimationDuration)),
                      scheduler: DispatchQueue.main,
                      latest: true)
            .sink { [weak self] displayContentWarning in
                guard let self = self else { return }

                if self.spoilerTextField.isHidden && self.textView.isFirstResponder && displayContentWarning {
                    self.spoilerTextField.becomeFirstResponder()
                } else if !self.spoilerTextField.isHidden
                            && self.spoilerTextField.isFirstResponder
                            && !displayContentWarning {
                    self.textView.becomeFirstResponder()
                }

                UIView.animate(withDuration: .zeroIfReduceMotion(.shortAnimationDuration)) {
                    self.spoilerTextField.isHidden_stackViewSafe = !displayContentWarning
                    textViewBaselineConstraint.isActive = !displayContentWarning
                }
            }
            .store(in: &cancellables)

        parentViewModel.$identityContext
            .sink { [weak self] in
                guard let self = self else { return }

                let avatarURL = $0.appPreferences.animateAvatars == .everywhere
                    && !$0.appPreferences.shouldReduceMotion
                    ? $0.identity.account?.avatar
                    : $0.identity.account?.avatarStatic

                self.avatarImageView.kf.setImage(with: avatarURL)
                self.changeIdentityButton.accessibilityLabel = $0.identity.handle
                self.changeIdentityButton.accessibilityHint =
                    NSLocalizedString("compose.change-identity-button.accessibility-hint", comment: "")
            }
            .store(in: &cancellables)

        parentViewModel.$authenticatedIdentities
            .sink { [weak self] in self?.changeIdentityButton.menu = self?.changeIdentityMenu(identities: $0) }
            .store(in: &cancellables)

        viewModel.$attachmentViewModels
            .throttle(for: .seconds(TimeInterval.zeroIfReduceMotion(.shortAnimationDuration)),
                      scheduler: DispatchQueue.main,
                      latest: true)
            .sink { [weak self] attachmentViewModels in
                UIView.animate(withDuration: .zeroIfReduceMotion(.shortAnimationDuration)) {
                    self?.attachmentsView.viewModel = self?.viewModel
                    self?.attachmentsView.isHidden_stackViewSafe = attachmentViewModels.isEmpty
                    self?.markAttachmentsSensitiveView.isHidden_stackViewSafe = attachmentViewModels.isEmpty
                }
            }
            .store(in: &cancellables)

        viewModel.$canAddAttachment
            .sink { [weak self] in self?.textView.canPasteImage = $0 }
            .store(in: &cancellables)

        textView.pastedItemProviders.sink { [weak self] in
            guard let self = self else { return }

            self.viewModel.attach(itemProvider: $0,
                                  parentViewModel: self.parentViewModel)
        }
        .store(in: &cancellables)

        viewModel.$displayPoll
            .throttle(for: .seconds(TimeInterval.zeroIfReduceMotion(.shortAnimationDuration)),
                      scheduler: DispatchQueue.main,
                      latest: true)
            .sink { [weak self] displayPoll in
                if !displayPoll {
                    self?.textView.becomeFirstResponder()
                }

                UIView.animate(withDuration: .zeroIfReduceMotion(.shortAnimationDuration)) {
                    self?.pollView.isHidden_stackViewSafe = !displayPoll
                }
            }
            .store(in: &cancellables)

        let guide = UIDevice.current.userInterfaceIdiom == .pad ? readableContentGuide : layoutMarginsGuide
        let constraints = [
            avatarImageView.heightAnchor.constraint(equalToConstant: .avatarDimension),
            avatarImageView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            avatarImageView.topAnchor.constraint(equalTo: guide.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: guide.bottomAnchor),
            changeIdentityButton.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            changeIdentityButton.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            changeIdentityButton.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            changeIdentityButton.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
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

    func changeIdentityMenu(identities: [Identity]) -> UIMenu {
        let processor = RoundCornerImageProcessor(radius: .widthFraction(0.5))
        var imageOptions = KingfisherManager.shared.defaultOptions

        imageOptions.append(.processor(processor))

        return UIMenu(children: identities.map { identity in
            UIDeferredMenuElement { completion in
                let action = UIAction(title: identity.handle) { [weak self] _ in
                    self?.parentViewModel.changeIdentity(identity)
                }

                if let image = identity.image {
                    KingfisherManager.shared.retrieveImage(with: image, options: imageOptions) {
                        if case let .success(value) = $0 {
                            action.image = value.image
                        }

                        completion([action])
                    }
                } else {
                    completion([action])
                }
            }
        })
    }
}
