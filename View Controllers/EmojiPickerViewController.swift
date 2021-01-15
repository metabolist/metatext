// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class EmojiPickerViewController: UIViewController {
    let searchBar = UISearchBar()

    private let viewModel: EmojiPickerViewModel
    private let selectionAction: (PickerEmoji) -> Void
    private let dismissAction: () -> Void
    private var cancellables = Set<AnyCancellable>()

    private lazy var collectionView: UICollectionView = {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(.minimumButtonDimension),
            heightDimension: .absolute(.minimumButtonDimension))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(.minimumButtonDimension))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        group.interItemSpacing = .flexible(.defaultSpacing)

        let section = NSCollectionLayoutSection(group: group)

        section.interGroupSpacing = .defaultSpacing
        section.contentInsets = NSDirectionalEdgeInsets(
            top: .defaultSpacing,
            leading: .defaultSpacing,
            bottom: .defaultSpacing,
            trailing: .defaultSpacing)

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(.defaultSpacing))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: Self.headerElementKind,
            alignment: .top)

        section.boundarySupplementaryItems = [header]

        let layout = UICollectionViewCompositionalLayout(section: section)

        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<PickerEmoji.Category, PickerEmoji> = {
        let cellRegistration = UICollectionView.CellRegistration
        <EmojiCollectionViewCell, PickerEmoji> {
            $0.emoji = $2
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration
        <EmojiCategoryHeaderView>(elementKind: "Header") { [weak self] in
            $0.label.text = self?.dataSource.snapshot().sectionIdentifiers[$2.section].displayName
        }

        let dataSource = UICollectionViewDiffableDataSource
        <PickerEmoji.Category, PickerEmoji>(collectionView: collectionView) {
            $0.dequeueConfiguredReusableCell(using: cellRegistration, for: $1, item: $2)
        }

        dataSource.supplementaryViewProvider = {
            $0.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: $2)
        }

        return dataSource
    }()

    init(viewModel: EmojiPickerViewModel,
         selectionAction: @escaping (PickerEmoji) -> Void,
         dismissAction: @escaping () -> Void) {
        self.viewModel = viewModel
        self.selectionAction = selectionAction
        self.dismissAction = dismissAction

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = NSLocalizedString("emoji.search", comment: "")
        searchBar.searchTextField.addAction(
            UIAction { [weak self] _ in self?.viewModel.query = self?.searchBar.text ?? "" },
            for: .editingChanged)

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = dataSource
        collectionView.delegate = self

        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        viewModel.$emoji
            .sink { [weak self] in self?.dataSource.apply($0.snapshot()) }
            .store(in: &cancellables)

        if let currentKeyboardLanguageIdentifier = searchBar.textInputMode?.primaryLanguage {
            viewModel.locale = Locale(identifier: currentKeyboardLanguageIdentifier)
        }

        NotificationCenter.default.publisher(for: UITextInputMode.currentInputModeDidChangeNotification)
            .compactMap { [weak self] _ in self?.searchBar.textInputMode?.primaryLanguage }
            .compactMap(Locale.init(identifier:))
            .assign(to: \.locale, on: viewModel)
            .store(in: &cancellables)

        publisher(for: \.isBeingDismissed).print().sink { (_) in

        }
        .store(in: &cancellables)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let containerView = popoverPresentationController?.containerView else { return }

        // gets the popover presentation controller's built-in visual effect view to actually show
        func setClear(view: UIView) {
            view.backgroundColor = .clear

            if view == self.view {
                return
            }

            for view in view.subviews {
                setClear(view: view)
            }
        }

        setClear(view: containerView)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        dismissAction()
    }
}

extension EmojiPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let emoji = dataSource.itemIdentifier(for: indexPath) else { return }

        selectionAction(emoji)

        UISelectionFeedbackGenerator().selectionChanged()
    }
}

private extension EmojiPickerViewController {
    static let headerElementKind = "com.metabolist.metatext.emoji-picker.header"
}
