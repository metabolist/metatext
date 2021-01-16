// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class EmojiPickerViewController: UIViewController {
    let searchBar = UISearchBar()

    private let viewModel: EmojiPickerViewModel
    private let selectionAction: (PickerEmoji) -> Void
    private let dismissAction: () -> Void
    private let skinToneButton = UIButton()
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
        <EmojiCollectionViewCell, PickerEmoji> { [weak self] in
            $0.emoji = self?.applyingDefaultSkinTone(emoji: $2) ?? $2
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

    private lazy var defaultSkinToneSelectionMenu: UIMenu = {
        let clearSkinToneAction = UIAction(title: SystemEmoji.SkinTone.noneExample) { [weak self] _ in
            self?.skinToneButton.setTitle(SystemEmoji.SkinTone.noneExample, for: .normal)
            self?.viewModel.identification.appPreferences.defaultEmojiSkinTone = nil
            self?.reloadVisibleItems()
        }

        let setSkinToneActions = SystemEmoji.SkinTone.allCases.map { [weak self] skinTone in
            UIAction(title: skinTone.example) { _ in
                self?.skinToneButton.setTitle(skinTone.example, for: .normal)
                self?.viewModel.identification.appPreferences.defaultEmojiSkinTone = skinTone
                self?.reloadVisibleItems()
            }
        }

        return UIMenu(
            title: NSLocalizedString("emoji.default-skin-tone", comment: ""),
            children: [clearSkinToneAction] + setSkinToneActions)
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

    // swiftlint:disable:next function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = NSLocalizedString("emoji.search", comment: "")
        searchBar.searchTextField.addAction(
            UIAction { [weak self] _ in self?.viewModel.query = self?.searchBar.text ?? "" },
            for: .editingChanged)

        view.addSubview(skinToneButton)
        skinToneButton.translatesAutoresizingMaskIntoConstraints = false
        skinToneButton.titleLabel?.adjustsFontSizeToFitWidth = true
        skinToneButton.setTitle(
            viewModel.identification.appPreferences.defaultEmojiSkinTone?.example ?? SystemEmoji.SkinTone.noneExample,
            for: .normal)
        skinToneButton.showsMenuAsPrimaryAction = true
        skinToneButton.menu = defaultSkinToneSelectionMenu

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = dataSource
        collectionView.delegate = self

        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            skinToneButton.leadingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: .defaultSpacing),
            skinToneButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            skinToneButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            skinToneButton.bottomAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        viewModel.$emoji
            .sink { [weak self] in self?.dataSource.apply(
                $0.snapshot(),
                animatingDifferences: !UIAccessibility.isReduceMotionEnabled) }
            .store(in: &cancellables)

        if let currentKeyboardLanguageIdentifier = searchBar.textInputMode?.primaryLanguage {
            viewModel.locale = Locale(identifier: currentKeyboardLanguageIdentifier)
        }

        NotificationCenter.default.publisher(for: UITextInputMode.currentInputModeDidChangeNotification)
            .compactMap { [weak self] _ in self?.searchBar.textInputMode?.primaryLanguage }
            .compactMap(Locale.init(identifier:))
            .assign(to: \.locale, on: viewModel)
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
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        select(emoji: applyingDefaultSkinTone(emoji: item))
        viewModel.updateUse(emoji: item)
    }

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath),
              case let .system(emoji, inFrequentlyUsed) = item,
              !emoji.skinToneVariations.isEmpty
        else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: ([emoji] + emoji.skinToneVariations).map { skinToneVariation in
                UIAction(title: skinToneVariation.emoji) { [weak self] _ in
                    self?.select(emoji: .system(skinToneVariation, inFrequentlyUsed: inFrequentlyUsed))
                    self?.viewModel.updateUse(emoji: item)
                }
            })
        }
    }
}

private extension EmojiPickerViewController {
    static let headerElementKind = "com.metabolist.metatext.emoji-picker.header"

    func select(emoji: PickerEmoji) {
        selectionAction(emoji)

        UISelectionFeedbackGenerator().selectionChanged()
    }

    func reloadVisibleItems() {
        var snapshot = dataSource.snapshot()
        let visibleItems = collectionView.indexPathsForVisibleItems.compactMap(dataSource.itemIdentifier(for:))

        snapshot.reloadItems(visibleItems)
        dataSource.apply(snapshot)
    }

    func applyingDefaultSkinTone(emoji: PickerEmoji) -> PickerEmoji {
        if case let .system(systemEmoji, inFrequentlyUsed) = emoji,
           let defaultEmojiSkinTone = viewModel.identification.appPreferences.defaultEmojiSkinTone {
            return .system(systemEmoji.applying(skinTone: defaultEmojiSkinTone), inFrequentlyUsed: inFrequentlyUsed)
        } else {
            return emoji
        }
    }
}
