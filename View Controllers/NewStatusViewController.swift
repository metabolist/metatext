// Copyright © 2020 Metabolist. All rights reserved.

import AVFoundation
import Combine
import Mastodon
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import ViewModels

final class NewStatusViewController: UIViewController {
    private let viewModel: NewStatusViewModel
    private let rootViewModel: RootViewModel?
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let activityIndicatorView = UIActivityIndicatorView(style: .large)
    private let postButton = UIBarButtonItem(title: nil, style: .done, target: nil, action: nil)
    private let mediaSelections = PassthroughSubject<[PHPickerResult], Never>()
    private let imagePickerResults = PassthroughSubject<[UIImagePickerController.InfoKey: Any]?, Never>()
    private let documentPickerResuls = PassthroughSubject<[URL]?, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: NewStatusViewModel, rootViewModel: RootViewModel?) {
        self.viewModel = viewModel
        self.rootViewModel = rootViewModel

        super.init(nibName: nil, bundle: nil)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidChangeFrameNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
            .sink { [weak self] in self?.adjustContentInset(notification: $0) }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // swiftlint:disable:next function_body_length
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

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in self?.dismiss() })
        navigationItem.rightBarButtonItem = postButton

        let postActionTitle = self.postActionTitle(
            statusWord: viewModel.identityContext.appPreferences.statusWord,
            visibility: viewModel.visibility)

        postButton.primaryAction = UIAction(title: postActionTitle) { [weak self] _ in
            self?.viewModel.post()
        }

        #if !IS_SHARE_EXTENSION
        if let inReplyToViewModel = viewModel.inReplyToViewModel {
            let statusView = StatusView(configuration: .init(viewModel: inReplyToViewModel))

            statusView.isUserInteractionEnabled = false
            statusView.bodyView.alpha = 0.5
            statusView.buttonsStackView.isHidden_stackViewSafe = true

            stackView.addArrangedSubview(statusView)
        }
        #endif

        setupViewModelBindings()
    }
}

extension NewStatusViewController {
    static let newStatusPostedNotification = Notification.Name("com.metabolist.metatext.new-status-posted-notification")
}

extension NewStatusViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true) {
            self.mediaSelections.send(results)
        }
    }
}

extension NewStatusViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        dismiss(animated: true) {
            self.imagePickerResults.send(info)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true) {
            self.imagePickerResults.send(nil)
        }
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
        case let .changeIdentity(identity):
            changeIdentity(identity)
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
            NotificationCenter.default.post(.init(name: Self.newStatusPostedNotification))
            dismiss()
        }
    }

    func set(compositionViewModels: [CompositionViewModel]) {
        let diff = compositionViewModels.map(\.id)
            .difference(from: stackView.arrangedSubviews.compactMap { ($0 as? CompositionView)?.id })

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
            guard case let .remove(_, id, _) = removal,
                  let index = stackView.arrangedSubviews.firstIndex(where: { ($0 as? CompositionView)?.id == id })
            else { continue }

            if (stackView.arrangedSubviews[index] as? CompositionView)?.textView.isFirstResponder ?? false {
                if index > 0 {
                    (stackView.arrangedSubviews[index - 1] as? CompositionView)?.textView.becomeFirstResponder()
                } else if stackView.arrangedSubviews.count > index {
                    (stackView.arrangedSubviews[index + 1] as? CompositionView)?.textView.becomeFirstResponder()
                }
            }

            stackView.arrangedSubviews[index].removeFromSuperview()
        }

        for compositionView in stackView.arrangedSubviews.compactMap({ $0 as? CompositionView }) {
            compositionView.removeButton.isHidden_stackViewSafe = compositionViewModels.count == 1
            compositionView.inReplyToView.isHidden_stackViewSafe = compositionView === stackView.arrangedSubviews.first
                && viewModel.inReplyToViewModel == nil
            compositionView.hasReplyFollowingView.isHidden_stackViewSafe =
                compositionView === stackView.arrangedSubviews.last
        }
    }

    func dismiss() {
        if let extensionContext = extensionContext {
            extensionContext.completeRequest(returningItems: nil)
        } else {
            rootViewModel?.navigationViewModel?.presentedNewStatusViewModel = nil
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
        viewModel.$postingState
            .sink { [weak self] in self?.apply(postingState: $0) }
            .store(in: &cancellables)
        viewModel.$alertItem
            .compactMap { $0 }
            .sink { [weak self] alertItem in
                guard let self = self else { return }

                if self.presentedViewController != nil {
                    self.dismiss(animated: true) {
                        self.present(alertItem: alertItem)
                    }
                } else {
                    self.present(alertItem: alertItem)
                }
            }
            .store(in: &cancellables)
        viewModel.$visibility.removeDuplicates().sink { [weak self] in
            guard let self = self else { return }

            let postActionTitle = self.postActionTitle(
                statusWord: self.viewModel.identityContext.appPreferences.statusWord,
                visibility: $0)

            self.postButton.primaryAction = UIAction(title: postActionTitle) { [weak self] _ in
                self?.viewModel.post()
            }
        }
        .store(in: &cancellables)
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
        present(picker, animated: true)
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
        picker.modalPresentationStyle = .overFullScreen
        picker.delegate = self

        if compositionViewModel.canAddNonImageAttachment {
            picker.mediaTypes = [UTType.image.description, UTType.movie.description]
        } else {
            picker.mediaTypes = [UTType.image.description]
        }

        present(picker, animated: true)
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
        present(documentPickerController, animated: true)
    }

    func presentEmojiPicker(tag: Int) {
        guard let fromView = view.viewWithTag(tag) else { return }

        if fromView.inputView == nil {
            let emojiPickerViewModel = EmojiPickerViewModel(identityContext: viewModel.identityContext)

            emojiPickerViewModel.$alertItem.assign(to: \.alertItem, on: viewModel).store(in: &cancellables)

            let emojiPickerController =
                EmojiPickerViewController(viewModel: emojiPickerViewModel) { [weak self] picker, emoji in
                    guard let textInput = fromView as? UITextInput,
                          let selectedTextRange = textInput.selectedTextRange
                    else { return }

                    textInput.replace(selectedTextRange, withText: emoji.escaped.appending(" "))

                    if (self?.presentedViewController as? UINavigationController)?.viewControllers.first === picker {
                        self?.dismiss(animated: true)
                    }
                } deletionAction: { _ in
                    (fromView as? UITextInput)?.deleteBackward()
                } searchPresentationAction: { [weak self] picker, navigation in
                    (fromView as? UITextView)?.inputView = nil
                    (fromView as? UITextField)?.inputView = nil
                    fromView.reloadInputViews()

                    navigation.removeFromParent()
                    navigation.preferredContentSize = CGSize(width: 100, height: 100)
                    picker.searchBar.becomeFirstResponder()
                    self?.present(navigation, animated: true)
                }

            let pickerNavigation = UINavigationController(rootViewController: emojiPickerController)

            (fromView as? UITextView)?.inputView = pickerNavigation.view
            (fromView as? UITextField)?.inputView = pickerNavigation.view
        } else {
            (fromView as? UITextView)?.inputView = nil
            (fromView as? UITextField)?.inputView = nil
        }

        fromView.reloadInputViews()
    }

    func presentAttachmentEditor(attachmentViewModel: AttachmentViewModel, compositionViewModel: CompositionViewModel) {
        let editAttachmentsView = EditAttachmentView { (attachmentViewModel, compositionViewModel) }
        let editAttachmentViewController = UIHostingController(rootView: editAttachmentsView)
        let navigationController = UINavigationController(rootViewController: editAttachmentViewController)

        navigationController.modalPresentationStyle = .overFullScreen
        present(navigationController, animated: true)
    }

    func changeIdentity(_ identity: Identity) {
        if viewModel.compositionViewModels.contains(where: { !$0.attachmentViewModels.isEmpty }) {
            let alertController = UIAlertController(
                title: nil,
                message: NSLocalizedString("compose.attachments-will-be-discarded", comment: ""),
                preferredStyle: .alert)

            let okAction = UIAlertAction(
                title: NSLocalizedString("ok", comment: ""),
                style: .destructive) { [weak self] _ in
                guard let self = self else { return }

                for compositionViewModel in self.viewModel.compositionViewModels {
                    compositionViewModel.discardAttachments()
                }

                self.viewModel.setIdentity(identity)
            }
            let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel) { _ in }

            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true)
        } else {
            viewModel.setIdentity(identity)
        }
    }

    func adjustContentInset(notification: Notification) {
        guard let keyboardFrameEnd = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }

        let convertedFrame = self.view.convert(keyboardFrameEnd, from: view.window)
        let contentInsetBottom: CGFloat

        if notification.name == UIResponder.keyboardWillHideNotification {
            contentInsetBottom = 0
        } else {
            contentInsetBottom = convertedFrame.height - view.safeAreaInsets.bottom
        }

        self.scrollView.contentInset.bottom = contentInsetBottom
        self.scrollView.verticalScrollIndicatorInsets.bottom = contentInsetBottom
    }

    func postActionTitle(statusWord: AppPreferences.StatusWord, visibility: Status.Visibility) -> String {
        switch (statusWord, visibility) {
        case (_, .direct):
            return NSLocalizedString("send", comment: "")
        case (.toot, _):
            return NSLocalizedString("toot", comment: "")
        case (.post, _):
            return NSLocalizedString("post", comment: "")
        }
    }
}
