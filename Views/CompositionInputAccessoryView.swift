// Copyright © 2020 Metabolist. All rights reserved.

import AVFoundation
import Combine
import Mastodon
import UIKit
import ViewModels

final class CompositionInputAccessoryView: UIToolbar {
    let tagForInputView = UUID().hashValue

    private let viewModel: CompositionViewModel
    private let parentViewModel: NewStatusViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: CompositionViewModel, parentViewModel: NewStatusViewModel) {
        self.viewModel = viewModel
        self.parentViewModel = parentViewModel

        super.init(
            frame: .init(
                origin: .zero,
                size: .init(width: UIScreen.main.bounds.width, height: .minimumButtonDimension)))

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension CompositionInputAccessoryView {
    // swiftlint:disable:next function_body_length
    func initialSetup() {
        autoresizingMask = .flexibleHeight

        heightAnchor.constraint(equalToConstant: .minimumButtonDimension).isActive = true

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

        let attachmentButton = UIBarButtonItem(
            image: UIImage(systemName: "paperclip"),
            menu: UIMenu(children: attachmentActions))
        let pollButton = UIBarButtonItem(
            image: UIImage(systemName: "chart.bar.xaxis"),
            primaryAction: UIAction { [weak self] _ in self?.viewModel.displayPoll.toggle() })
        let visibilityButton = UIBarButtonItem(
            image: UIImage(systemName: parentViewModel.visibility.systemImageName),
            menu: UIMenu(children: Status.Visibility.allCasesExceptUnknown.reversed().map { visibility in
                UIAction(
                    title: visibility.title ?? "",
                    image: UIImage(systemName: visibility.systemImageName),
                    discoverabilityTitle: visibility.description) { [weak self] _ in
                    self?.parentViewModel.visibility = visibility
                }
            }))
        let contentWarningButton = UIBarButtonItem(
            title: NSLocalizedString("status.content-warning-abbreviation", comment: ""),
            primaryAction: UIAction { [weak self] _ in self?.viewModel.displayContentWarning.toggle() })
        let emojiButton = UIBarButtonItem(
            image: UIImage(systemName: "face.smiling"),
            primaryAction: UIAction { [weak self] _ in
                guard let self = self else { return }

                self.parentViewModel.presentEmojiPicker(tag: self.tagForInputView)
            })
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            primaryAction: UIAction { [weak self] _ in
                guard let self = self else { return }

                self.parentViewModel.insert(after: self.viewModel)
            })

        let charactersLabel = UILabel()

        charactersLabel.font = .preferredFont(forTextStyle: .callout)
        charactersLabel.adjustsFontForContentSizeCategory = true
        charactersLabel.adjustsFontSizeToFitWidth = true

        let charactersBarItem = UIBarButtonItem(customView: charactersLabel)

        items = [
            attachmentButton,
            UIBarButtonItem.fixedSpace(.defaultSpacing),
            pollButton,
            UIBarButtonItem.fixedSpace(.defaultSpacing),
            visibilityButton,
            UIBarButtonItem.fixedSpace(.defaultSpacing),
            contentWarningButton,
            UIBarButtonItem.fixedSpace(.defaultSpacing),
            emojiButton,
            UIBarButtonItem.flexibleSpace(),
            charactersBarItem,
            UIBarButtonItem.fixedSpace(.defaultSpacing),
            addButton]

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
            .sink { addButton.isEnabled = $0 }
            .store(in: &cancellables)

        parentViewModel.$visibility
            .sink { visibilityButton.image = UIImage(systemName: $0.systemImageName) }
            .store(in: &cancellables)
    }
}
