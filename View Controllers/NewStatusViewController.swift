// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Kingfisher
import PhotosUI
import UIKit
import ViewModels

class NewStatusViewController: UICollectionViewController {
    private let viewModel: NewStatusViewModel
    private let isShareExtension: Bool
    private let postButton = UIBarButtonItem(
        title: NSLocalizedString("post", comment: ""),
        style: .done,
        target: nil,
        action: nil)
    private var attachMediaTo: CompositionViewModel?
    private var cancellables = Set<AnyCancellable>()

    private lazy var dataSource: NewStatusDataSource = {
        .init(collectionView: collectionView, viewModelProvider: viewModel.viewModel(indexPath:))
    }()

    init(viewModel: NewStatusViewModel, isShareExtension: Bool) {
        self.viewModel = viewModel
        self.isShareExtension = isShareExtension

        let configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)

        super.init(collectionViewLayout: layout)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = dataSource

        view.backgroundColor = .systemBackground

        postButton.primaryAction = UIAction(title: NSLocalizedString("post", comment: "")) { [weak self] _ in
            self?.viewModel.post()
        }

        setupBarButtonItems(identification: viewModel.identification)

        viewModel.$identification
            .sink { [weak self] in
                guard let self = self else { return }

                self.setupBarButtonItems(identification: $0)
            }
            .store(in: &cancellables)

        viewModel.$compositionViewModels.sink { [weak self] in
            guard let self = self else { return }

            let oldSnapshot = self.dataSource.snapshot()
            let newSnapshot = [$0.map(\.composition.id)].snapshot()
            let diff = newSnapshot.itemIdentifiers.difference(from: oldSnapshot.itemIdentifiers)

            self.dataSource.apply(newSnapshot) {
                if case let .insert(_, id, _) = diff.insertions.first,
                   let indexPath = self.dataSource.indexPath(for: id) {
                    self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .top)
                }
            }
        }
        .store(in: &cancellables)

        viewModel.$compositionViewModels
            .flatMap { Publishers.MergeMany($0.map(\.composition.$text)) }
            .sink { [weak self] _ in self?.collectionView.collectionViewLayout.invalidateLayout() }
            .store(in: &cancellables)

        viewModel.$canPost.sink { [weak self] in self?.postButton.isEnabled = $0 }.store(in: &cancellables)

        viewModel.events.sink { [weak self] in self?.handle(event: $0) }.store(in: &cancellables)

        viewModel.$alertItem
            .compactMap { $0 }
            .sink { [weak self] in self?.present(alertItem: $0) }
            .store(in: &cancellables)
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        setupBarButtonItems(identification: viewModel.identification)
    }

    func setupBarButtonItems(identification: Identification) {
        let target = isShareExtension ? self : parent
        let closeButton = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in self?.dismiss() })

        target?.navigationItem.leftBarButtonItem = closeButton
        target?.navigationItem.titleView = viewModel.canChangeIdentity
            ? changeIdentityButton(identification: identification)
            : nil
        target?.navigationItem.rightBarButtonItem = postButton
    }

    func dismiss() {
        if isShareExtension {
            extensionContext?.completeRequest(returningItems: nil)
        } else {
            presentingViewController?.dismiss(animated: true)
        }
    }
}

extension NewStatusViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        guard let result = results.first else { return }

        attachMediaTo?.attach(itemProvider: result.itemProvider)
        attachMediaTo = nil
    }
}

private extension NewStatusViewController {
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

    func handle(event: CompositionViewModel.Event) {
        switch event {
        case let .presentMediaPicker(compositionViewModel):
            attachMediaTo = compositionViewModel

            var configuration = PHPickerConfiguration()

            configuration.preferredAssetRepresentationMode = .current

            let picker = PHPickerViewController(configuration: configuration)

            picker.delegate = self
            present(picker, animated: true)
        default:
            break
        }
    }
}
