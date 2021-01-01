// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Kingfisher
import PhotosUI
import UIKit
import ViewModels

final class NewStatusViewController: UIViewController {
    private let viewModel: NewStatusViewModel
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let postButton = UIBarButtonItem(
        title: NSLocalizedString("post", comment: ""),
        style: .done,
        target: nil,
        action: nil)
    private let mediaSelections = PassthroughSubject<[PHPickerResult], Never>()
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

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        postButton.primaryAction = UIAction(title: NSLocalizedString("post", comment: "")) { [weak self] _ in
            self?.viewModel.post()
        }

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

private extension NewStatusViewController {
    func handle(event: NewStatusViewModel.Event) {
        switch event {
        case let .presentMediaPicker(compositionViewModel):
            presentMediaPicker(compositionViewModel: compositionViewModel)
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
        viewModel.events.sink { [weak self] in self?.handle(event: $0) }.store(in: &cancellables)

        viewModel.$canPost.sink { [weak self] in self?.postButton.isEnabled = $0 }.store(in: &cancellables)

        viewModel.$compositionViewModels.sink { [weak self] in
            guard let self = self else { return }

            let diff = [$0.map(\.id)].snapshot().itemIdentifiers.difference(
                from: [self.stackView.arrangedSubviews.compactMap { ($0 as? CompositionView)?.id }]
                    .snapshot().itemIdentifiers)

            for insertion in diff.insertions {
                guard case let .insert(index, id, _) = insertion,
                      let compositionViewModel = $0.first(where: { $0.id == id })
                      else { continue }

                let compositionView = CompositionView(
                    viewModel: compositionViewModel,
                    parentViewModel: self.viewModel)
                self.stackView.insertArrangedSubview(compositionView, at: index)
                compositionView.textView.becomeFirstResponder()
                DispatchQueue.main.async {
                    self.scrollView.scrollRectToVisible(
                        self.scrollView.convert(compositionView.frame, from: self.stackView),
                        animated: true)
                }
            }

            for removal in diff.removals {
                guard case let .remove(_, id, _) = removal else { continue }

                self.stackView.arrangedSubviews.first { ($0 as? CompositionView)?.id == id }?.removeFromSuperview()
            }
        }
        .store(in: &cancellables)

        viewModel.$identification
            .sink { [weak self] in
                guard let self = self else { return }

                self.setupBarButtonItems(identification: $0)
            }
            .store(in: &cancellables)

        viewModel.$alertItem
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.present(alertItem: $0) }
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

        let picker = PHPickerViewController(configuration: configuration)

        picker.modalPresentationStyle = .overFullScreen
        picker.delegate = self
        present(picker, animated: true)
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
