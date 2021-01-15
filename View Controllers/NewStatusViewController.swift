// Copyright © 2020 Metabolist. All rights reserved.

import AVFoundation
import Combine
import Kingfisher
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import ViewModels

// swiftlint:disable file_length
final class NewStatusViewController: UIViewController {
    private let viewModel: NewStatusViewModel
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let activityIndicatorView = UIActivityIndicatorView(style: .large)
    private let postButton = UIBarButtonItem(
        title: NSLocalizedString("post", comment: ""),
        style: .done,
        target: nil,
        action: nil)
    private let mediaSelections = PassthroughSubject<[PHPickerResult], Never>()
    private let imagePickerResults = PassthroughSubject<[UIImagePickerController.InfoKey: Any]?, Never>()
    private let documentPickerResuls = PassthroughSubject<[URL]?, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: NewStatusViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing

        scrollView.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            activityIndicatorView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])

        postButton.primaryAction = UIAction(title: NSLocalizedString("post", comment: "")) { [weak self] _ in
            self?.viewModel.post()
        }

        #if !IS_SHARE_EXTENSION
        if let inReplyToViewModel = viewModel.inReplyToViewModel {
            let statusView = StatusView(configuration: .init(viewModel: inReplyToViewModel))

            statusView.isUserInteractionEnabled = false
            statusView.bodyView.alpha = 0.5
            statusView.buttonsStackView.isHidden = true

            stackView.addArrangedSubview(statusView)
        }
        #endif

        setupViewModelBindings()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        setupBarButtonItems(identification: viewModel.identification)
    }
}

extension NewStatusViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        mediaSelections.send(results)
        dismiss(animated: true)
    }
}

extension NewStatusViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        imagePickerResults.send(info)
        dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePickerResults.send(nil)
        dismiss(animated: true)
    }
}

extension NewStatusViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        documentPickerResuls.send(urls)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        documentPickerResuls.send(nil)
    }
}

extension NewStatusViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController,
                                   traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        .none
    }
}

// Required by UIImagePickerController
extension NewStatusViewController: UINavigationControllerDelegate {}

private extension NewStatusViewController {
    func handle(event: NewStatusViewModel.Event) {
        switch event {
        case let .presentMediaPicker(compositionViewModel):
            presentMediaPicker(compositionViewModel: compositionViewModel)
        case let .presentCamera(compositionViewModel):
            #if !IS_SHARE_EXTENSION
            presentCamera(compositionViewModel: compositionViewModel)
            #endif
        case let .presentDocumentPicker(compositionViewModel):
            presentDocumentPicker(compositionViewModel: compositionViewModel)
        case let .presentEmojiPicker(tag):
            presentEmojiPicker(tag: tag)
        case let .editAttachment(attachmentViewModel, compositionViewModel):
            presentAttachmentEditor(
                attachmentViewModel: attachmentViewModel,
                compositionViewModel: compositionViewModel)
        }
    }

    func apply(postingState: NewStatusViewModel.PostingState) {
        switch postingState {
        case .composing:
            activityIndicatorView.stopAnimating()
            stackView.isUserInteractionEnabled = true
            stackView.alpha = 1
        case .posting:
            activityIndicatorView.startAnimating()
            stackView.isUserInteractionEnabled = false
            stackView.alpha = 0.5
        case .done:
            dismiss()
        }
    }

    func set(compositionViewModels: [CompositionViewModel]) {
        let diff = compositionViewModels.map(\.id).snapshot().itemIdentifiers.difference(
            from: stackView.arrangedSubviews.compactMap { ($0 as? CompositionView)?.id }
                .snapshot().itemIdentifiers)

        for insertion in diff.insertions {
            guard case let .insert(index, id, _) = insertion,
                  let compositionViewModel = compositionViewModels.first(where: { $0.id == id })
                  else { continue }

            let compositionView = CompositionView(
                viewModel: compositionViewModel,
                parentViewModel: viewModel)
            let adjustedIndex = viewModel.inReplyToViewModel == nil ? index : index + 1

            stackView.insertArrangedSubview(compositionView, at: adjustedIndex)
            compositionView.textView.becomeFirstResponder()

            DispatchQueue.main.async {
                self.scrollView.scrollRectToVisible(
                    self.scrollView.convert(compositionView.frame, from: self.stackView),
                    animated: true)
            }
        }

        for removal in diff.removals {
            guard case let .remove(_, id, _) = removal else { continue }

            stackView.arrangedSubviews.first { ($0 as? CompositionView)?.id == id }?.removeFromSuperview()
        }

        for compositionView in stackView.arrangedSubviews.compactMap({ $0 as? CompositionView }) {
            compositionView.removeButton.isHidden = compositionViewModels.count == 1
            compositionView.inReplyToView.isHidden = compositionView === stackView.arrangedSubviews.first
                && viewModel.inReplyToViewModel == nil
            compositionView.hasReplyFollowingView.isHidden = compositionView === stackView.arrangedSubviews.last
        }
    }

    func dismiss() {
        if let extensionContext = extensionContext {
            extensionContext.completeRequest(returningItems: nil)
        } else {
            presentingViewController?.dismiss(animated: true)
        }
    }

    func setupViewModelBindings() {
        viewModel.events
            .sink { [weak self] in self?.handle(event: $0) }
            .store(in: &cancellables)
        viewModel.$canPost
            .sink { [weak self] in self?.postButton.isEnabled = $0 }
            .store(in: &cancellables)
        viewModel.$compositionViewModels
            .sink { [weak self] in self?.set(compositionViewModels: $0) }
            .store(in: &cancellables)
        viewModel.$identification
            .sink { [weak self] in self?.setupBarButtonItems(identification: $0) }
            .store(in: &cancellables)
        viewModel.$postingState
            .sink { [weak self] in self?.apply(postingState: $0) }
            .store(in: &cancellables)
        viewModel.$alertItem
            .compactMap { $0 }
            .sink { [weak self] alertItem in
                self?.dismissEmojiPickerIfPresented {
                    self?.present(alertItem: alertItem)
                }
            }
            .store(in: &cancellables)
    }

    func setupBarButtonItems(identification: Identification) {
        let closeButton = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in self?.dismiss() })

        parent?.navigationItem.leftBarButtonItem = closeButton
        parent?.navigationItem.titleView = viewModel.canChangeIdentity
            ? changeIdentityButton(identification: identification)
            : nil
        parent?.navigationItem.rightBarButtonItem = postButton
    }

    func presentMediaPicker(compositionViewModel: CompositionViewModel) {
        mediaSelections.first().sink { [weak self] results in
            guard let self = self, let result = results.first else { return }

            self.viewModel.attach(itemProvider: result.itemProvider, to: compositionViewModel)
        }
        .store(in: &cancellables)

        var configuration = PHPickerConfiguration()

        configuration.preferredAssetRepresentationMode = .current

        if !compositionViewModel.canAddNonImageAttachment {
            configuration.filter = .images
        }

        let picker = PHPickerViewController(configuration: configuration)

        picker.modalPresentationStyle = .overFullScreen
        picker.delegate = self
        dismissEmojiPickerIfPresented {
            self.present(picker, animated: true)
        }
    }

    #if !IS_SHARE_EXTENSION
    func presentCamera(compositionViewModel: CompositionViewModel) {
        if AVCaptureDevice.authorizationStatus(for: .video) == .denied {
            let alertController = UIAlertController(
                title: NSLocalizedString("camera-access.title", comment: ""),
                message: NSLocalizedString("camera-access.description", comment: ""),
                preferredStyle: .alert)

            let openSystemSettingsAction = UIAlertAction(
                title: NSLocalizedString("camera-access.open-system-settings", comment: ""),
                style: .default) { _ in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

                UIApplication.shared.open(settingsUrl)
            }
            let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel) { _ in }

            alertController.addAction(openSystemSettingsAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true)

            return
        }

        imagePickerResults.first().sink { [weak self] in
            guard let self = self, let info = $0 else { return }

            if let url = info[.mediaURL] as? URL, let itemProvider = NSItemProvider(contentsOf: url) {
                self.viewModel.attach(itemProvider: itemProvider, to: compositionViewModel)
            } else if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                self.viewModel.attach(itemProvider: NSItemProvider(object: image), to: compositionViewModel)
            }
        }
        .store(in: &cancellables)

        let picker = UIImagePickerController()

        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.modalPresentationStyle = .overFullScreen
        picker.delegate = self

        if compositionViewModel.canAddNonImageAttachment {
            picker.mediaTypes = [UTType.image.description, UTType.movie.description]
        } else {
            picker.mediaTypes = [UTType.image.description]
        }

        dismissEmojiPickerIfPresented {
            self.present(picker, animated: true)
        }
    }
    #endif

    func presentDocumentPicker(compositionViewModel: CompositionViewModel) {
        documentPickerResuls.first().sink { [weak self] in
            guard let self = self,
                  let result = $0?.first,
                  result.startAccessingSecurityScopedResource(),
                  let itemProvider = NSItemProvider(contentsOf: result)
            else { return }

            self.viewModel.attach(itemProvider: itemProvider, to: compositionViewModel)
            result.stopAccessingSecurityScopedResource()
        }
        .store(in: &cancellables)

        let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: [.image, .movie, .audio])

        documentPickerController.delegate = self
        documentPickerController.allowsMultipleSelection = false
        documentPickerController.modalPresentationStyle = .overFullScreen
        dismissEmojiPickerIfPresented {
            self.present(documentPickerController, animated: true)
        }
    }

    func presentEmojiPicker(tag: Int) {
        if dismissEmojiPickerIfPresented() {
            return
        }

        guard let fromView = view.viewWithTag(tag) else { return }

        let emojiPickerViewModel = EmojiPickerViewModel(identification: viewModel.identification)

        emojiPickerViewModel.$alertItem.assign(to: \.alertItem, on: viewModel).store(in: &cancellables)

        let emojiPickerController = EmojiPickerViewController(viewModel: emojiPickerViewModel) {
            guard let textInput = fromView as? UITextInput else { return }

            let emojiString: String

            switch $0 {
            case let .custom(emoji):
                emojiString = ":\(emoji.shortcode):"
            case let .system(emoji):
                emojiString = emoji.emoji
            }

            if let selectedTextRange = textInput.selectedTextRange {
                textInput.replace(selectedTextRange, withText: emojiString.appending(" "))
            }
        } dismissAction: {
            fromView.becomeFirstResponder()
        }

        emojiPickerController.searchBar.inputAccessoryView = fromView.inputAccessoryView
        emojiPickerController.preferredContentSize = .init(
            width: view.readableContentGuide.layoutFrame.width,
            height: view.frame.height)
        emojiPickerController.modalPresentationStyle = .popover
        emojiPickerController.popoverPresentationController?.delegate = self
        emojiPickerController.popoverPresentationController?.sourceView = fromView
        emojiPickerController.popoverPresentationController?.sourceRect = fromView.bounds
        emojiPickerController.popoverPresentationController?.backgroundColor = .clear

        present(emojiPickerController, animated: true)
    }

    @discardableResult
    func dismissEmojiPickerIfPresented(completion: (() -> Void)? = nil) -> Bool {
        let emojiPickerPresented = presentedViewController is EmojiPickerViewController

        if emojiPickerPresented {
            dismiss(animated: true, completion: completion)
        }

        return emojiPickerPresented
    }

    func presentAttachmentEditor(attachmentViewModel: AttachmentViewModel, compositionViewModel: CompositionViewModel) {
        let editAttachmentsView = EditAttachmentView { (attachmentViewModel, compositionViewModel) }
        let editAttachmentViewController = UIHostingController(rootView: editAttachmentsView)
        let navigationController = UINavigationController(rootViewController: editAttachmentViewController)

        navigationController.modalPresentationStyle = .overFullScreen
        dismissEmojiPickerIfPresented {
            self.present(navigationController, animated: true)
        }
    }

    func changeIdentityButton(identification: Identification) -> UIButton {
        let changeIdentityButton = UIButton()
        let downsampled = KingfisherOptionsInfo.downsampled(
            dimension: .barButtonItemDimension,
            scaleFactor: UIScreen.main.scale)

        let menuItems = viewModel.authenticatedIdentities
            .filter { $0.id != identification.identity.id }
            .map { identity in
                UIDeferredMenuElement { completion in
                    let action = UIAction(title: identity.handle) { [weak self] _ in
                        self?.viewModel.setIdentity(identity)
                    }

                    if let image = identity.image {
                        KingfisherManager.shared.retrieveImage(with: image, options: downsampled) {
                            if case let .success(value) = $0 {
                                action.image = value.image
                            }

                            completion([action])
                        }
                    } else {
                        completion([action])
                    }
                }
            }

        changeIdentityButton.kf.setImage(
            with: identification.identity.image,
            for: .normal,
            options: downsampled)
        changeIdentityButton.showsMenuAsPrimaryAction = true
        changeIdentityButton.menu = UIMenu(children: menuItems)

        return changeIdentityButton
    }
}
// swiftlint:enable file_length
