// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Kingfisher
import UIKit
import ViewModels

class NewStatusViewController: UICollectionViewController {
    private let viewModel: NewStatusViewModel
    private let isShareExtension: Bool
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

        viewModel.$identification
            .sink { [weak self] in
                guard let self = self else { return }

                self.setupBarButtonItems(identification: $0)
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = dataSource

        view.backgroundColor = .systemBackground

        setupBarButtonItems(identification: viewModel.identification)

        viewModel.$compositionViewModels.sink { [weak self] in
            self?.dataSource.apply([$0.map(\.composition.id)].snapshot()) {
                DispatchQueue.main.async {
                    if let collectionView = self?.collectionView,
                       collectionView.indexPathsForSelectedItems?.isEmpty ?? false {
                        collectionView.selectItem(
                            at: collectionView.indexPathsForVisibleItems.first,
                            animated: false,
                            scrollPosition: .top)
                    }
                }
            }
        }
        .store(in: &cancellables)
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        setupBarButtonItems(identification: viewModel.identification)
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 willDisplay cell: UICollectionViewCell,
                                 forItemAt indexPath: IndexPath) {
        ((cell as? CompositionListCell)?.contentView as? CompositionView)?.textView.delegate = self
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
    }

    func dismiss() {
        if isShareExtension {
            extensionContext?.completeRequest(returningItems: nil)
        } else {
            presentingViewController?.dismiss(animated: true)
        }
    }
}

extension NewStatusViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        collectionView.collectionViewLayout.invalidateLayout()
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
}
