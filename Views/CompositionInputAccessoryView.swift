// Copyright © 2020 Metabolist. All rights reserved.

import AVFoundation
import Combine
import Mastodon
import UIKit
import ViewModels

final class CompositionInputAccessoryView: UIView {
    let visibilityButton = UIButton()
    let addButton = UIButton()
    let contentWarningButton = UIButton(type: .system)
    let tagForInputView = UUID().hashValue

    private let viewModel: CompositionViewModel
    private let parentViewModel: NewStatusViewModel
    private let stackView = UIStackView()
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: CompositionViewModel, parentViewModel: NewStatusViewModel) {
        self.viewModel = viewModel
        self.parentViewModel = parentViewModel

        super.init(frame: .zero)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
}

private extension CompositionInputAccessoryView {
    // swiftlint:disable:next function_body_length
    func initialSetup() {
        autoresizingMask = .flexibleHeight
        backgroundColor = .secondarySystemFill

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = .defaultSpacing

        var attachmentActions = [
            UIAction(
                title: NSLocalizedString("compose.browse", comment: ""),
                image: UIImage(systemName: "ellipsis")) { [weak self] _ in
                guard let self = self else { return }

                self.parentViewModel.presentDocumentPicker(viewModel: self.viewModel)
            },
            UIAction(
                title: NSLocalizedString("compose.photo-library", comment: ""),
                image: UIImage(systemName: "rectangle.on.rectangle")) { [weak self] _ in
                guard let self = self else { return }

                self.parentViewModel.presentMediaPicker(viewModel: self.viewModel)
            }
        ]

        #if !IS_SHARE_EXTENSION
        attachmentActions.insert(UIAction(
            title: NSLocalizedString("compose.take-photo-or-video", comment: ""),
            image: UIImage(systemName: "camera.fill")) { [weak self] _ in
            guard let self = self else { return }

            self.parentViewModel.presentCamera(viewModel: self.viewModel)
        },
        at: 1)
        #endif

        let attachmentButton = UIButton()
        stackView.addArrangedSubview(attachmentButton)
        attachmentButton.setImage(
            UIImage(
                systemName: "paperclip",
                withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .normal)
        attachmentButton.showsMenuAsPrimaryAction = true
        attachmentButton.menu = UIMenu(children: attachmentActions)

        let pollButton = UIButton(primaryAction: UIAction { [weak self] _ in self?.viewModel.displayPoll.toggle() })

        stackView.addArrangedSubview(pollButton)
        pollButton.setImage(
            UIImage(
                systemName: "chart.bar.xaxis",
                withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .normal)

        stackView.addArrangedSubview(visibilityButton)
        visibilityButton.showsMenuAsPrimaryAction = true
        visibilityButton.menu = UIMenu(children: Status.Visibility.allCasesExceptUnknown.reversed().map { visibility in
            UIAction(
                title: visibility.title ?? "",
                image: UIImage(systemName: visibility.systemImageName),
                discoverabilityTitle: visibility.description) { [weak self] _ in
                self?.parentViewModel.visibility = visibility
            }
        })

        stackView.addArrangedSubview(contentWarningButton)
        contentWarningButton.setTitle(
            NSLocalizedString("status.content-warning-abbreviation", comment: ""),
            for: .normal)
        contentWarningButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.displayContentWarning.toggle() },
            for: .touchUpInside)

        let emojiButton = UIButton(primaryAction: UIAction { [weak self] _ in
            guard let self = self else { return }

            self.parentViewModel.presentEmojiPicker(tag: self.tagForInputView)
        })

        stackView.addArrangedSubview(emojiButton)
        emojiButton.setImage(
            UIImage(
                systemName: "face.smiling",
                withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .normal)

        stackView.addArrangedSubview(UIView())

        let charactersLabel = UILabel()

        stackView.addArrangedSubview(charactersLabel)
        charactersLabel.font = .preferredFont(forTextStyle: .callout)

        stackView.addArrangedSubview(addButton)
        addButton.setImage(
            UIImage(
                systemName: "plus.circle.fill",
                withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .normal)
        addButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }

            self.parentViewModel.insert(after: self.viewModel)
        }, for: .touchUpInside)

        viewModel.$canAddAttachment
            .sink { attachmentButton.isEnabled = $0 }
            .store(in: &cancellables)

        viewModel.$attachmentViewModels
            .combineLatest(viewModel.$attachmentUpload)
            .sink { pollButton.isEnabled = $0.isEmpty && $1 == nil }
            .store(in: &cancellables)

        viewModel.$remainingCharacters.sink {
            charactersLabel.text = String($0)
            charactersLabel.textColor = $0 < 0 ? .systemRed : .label
        }
        .store(in: &cancellables)

        viewModel.$isPostable
            .sink { [weak self] in self?.addButton.isEnabled = $0 }
            .store(in: &cancellables)

        parentViewModel.$visibility
            .sink { [weak self] in
                self?.visibilityButton.setImage(UIImage(systemName: $0.systemImageName), for: .normal)
            }
            .store(in: &cancellables)

        for button in [attachmentButton, pollButton, visibilityButton, contentWarningButton, emojiButton, addButton] {
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: .minimumButtonDimension).isActive = true
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: .minimumButtonDimension).isActive = true
        }

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
