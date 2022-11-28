// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class EmojiPickerViewController: UICollectionViewController {
    let searchBar = UISearchBar()

    private let viewModel: EmojiPickerViewModel
    private let selectionAction: (EmojiPickerViewController, PickerEmoji) -> Void
    private let deletionAction: ((EmojiPickerViewController) -> Void)?
    private let searchPresentationAction: ((EmojiPickerViewController, UINavigationController) -> Void)?
    private let skinToneButton = UIBarButtonItem()
    private let deleteButton = UIBarButtonItem()
    private let closeButton = UIBarButtonItem(systemItem: .close)
    private let presentSearchButton = UIButton()
    private var cancellables = Set<AnyCancellable>()

    private lazy var dataSource: UICollectionViewDiffableDataSource<PickerEmoji.Category, PickerEmoji> = {
        let cellRegistration = UICollectionView.CellRegistration
        <EmojiCollectionViewCell, PickerEmoji> { [weak self] in
            guard let self = self else { return }

            $0.viewModel = EmojiViewModel(emoji: $2, identityContext: self.viewModel.identityContext)
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration
        <EmojiCategoryHeaderView>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] in
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
            self?.skinToneButton.title = SystemEmoji.SkinTone.noneExample
            self?.viewModel.identityContext.appPreferences.defaultEmojiSkinTone = nil
            self?.reloadVisibleItems()
        }

        let setSkinToneActions = SystemEmoji.SkinTone.allCases.map { [weak self] skinTone in
            UIAction(title: skinTone.example) { _ in
                self?.skinToneButton.title = skinTone.example
                self?.viewModel.identityContext.appPreferences.defaultEmojiSkinTone = skinTone
                self?.reloadVisibleItems()
            }
        }

        return UIMenu(
            title: NSLocalizedString("emoji.default-skin-tone", comment: ""),
            children: [clearSkinToneAction] + setSkinToneActions)
    }()

    init(viewModel: EmojiPickerViewModel,
         selectionAction: @escaping (EmojiPickerViewController, PickerEmoji) -> Void,
         deletionAction: ((EmojiPickerViewController) -> Void)?,
         searchPresentationAction: ((EmojiPickerViewController, UINavigationController) -> Void)?) {
        self.viewModel = viewModel
        self.selectionAction = selectionAction
        self.deletionAction = deletionAction
        self.searchPresentationAction = searchPresentationAction

        super.init(collectionViewLayout: Self.layout())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // swiftlint:disable:next function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = NSLocalizedString("emoji.search", comment: "")
        searchBar.searchTextField.addAction(
            UIAction { [weak self] _ in
                self?.viewModel.query = self?.searchBar.text ?? ""
                self?.collectionView.setContentOffset(.zero, animated: false)
            },
            for: .editingChanged)
        navigationItem.titleView = searchBar

        searchBar.addSubview(presentSearchButton)
        presentSearchButton.translatesAutoresizingMaskIntoConstraints = false
        presentSearchButton.accessibilityLabel = NSLocalizedString("emoji.search", comment: "")
        presentSearchButton.addAction(UIAction { [weak self] _ in self?.presentSearch() }, for: .touchUpInside)
        presentSearchButton.isHidden = searchPresentationAction == nil

        skinToneButton.accessibilityLabel =
            NSLocalizedString("emoji.default-skin-tone-button.accessibility-label", comment: "")

        skinToneButton.title = viewModel.identityContext.appPreferences.defaultEmojiSkinTone?.example
            ?? SystemEmoji.SkinTone.noneExample
        skinToneButton.accessibilityLabel =
            NSLocalizedString("emoji.default-skin-tone-button.accessibility-label", comment: "")
        skinToneButton.menu = defaultSkinToneSelectionMenu

        deleteButton.primaryAction = UIAction(image: UIImage(systemName: "delete.left")) { [weak self] _ in
            guard let self = self else { return }

            self.deletionAction?(self)
        }
        deleteButton.tintColor = .label

        if deletionAction != nil {
            navigationItem.rightBarButtonItems = [deleteButton, skinToneButton]
        } else {
            navigationItem.rightBarButtonItem = skinToneButton
        }

        closeButton.primaryAction = UIAction { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }

        collectionView.backgroundColor = .clear
        collectionView.dataSource = dataSource
        collectionView.isAccessibilityElement = false
        collectionView.shouldGroupAccessibilityChildren = true

        NSLayoutConstraint.activate([
            presentSearchButton.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor),
            presentSearchButton.topAnchor.constraint(equalTo: searchBar.topAnchor),
            presentSearchButton.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor),
            presentSearchButton.bottomAnchor.constraint(equalTo: searchBar.bottomAnchor)
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

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        select(emoji: item.applyingDefaultSkinTone(identityContext: viewModel.identityContext))
        viewModel.updateUse(emoji: item)
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 contextMenuConfigurationForItemAt indexPath: IndexPath,
                                 point: CGPoint) -> UIContextMenuConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath),
              case let .system(emoji, infrequentlyUsed) = item,
              !emoji.skinToneVariations.isEmpty
        else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: ([emoji] + emoji.skinToneVariations).map { skinToneVariation in
                UIAction(title: skinToneVariation.emoji) { [weak self] _ in
                    self?.select(emoji: .system(skinToneVariation, infrequentlyUsed: infrequentlyUsed))
                    self?.viewModel.updateUse(emoji: item)
                }
            })
        }
    }
}

private extension EmojiPickerViewController {
    static func layout() -> UICollectionViewLayout {
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
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top)

        section.boundarySupplementaryItems = [header]

        return UICollectionViewCompositionalLayout(section: section)
    }

    func select(emoji: PickerEmoji) {
        selectionAction(self, emoji)

        UISelectionFeedbackGenerator().selectionChanged()
    }

    func presentSearch() {
        guard let navigationController = self.navigationController else { return }

        presentSearchButton.isHidden = true
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItems = [self.skinToneButton]
        collectionView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        searchPresentationAction?(self, navigationController)
    }

    func reloadVisibleItems() {
        var snapshot = dataSource.snapshot()
        let visibleItems = collectionView.indexPathsForVisibleItems.compactMap(dataSource.itemIdentifier(for:))

        snapshot.reloadItems(visibleItems)
        dataSource.apply(snapshot)
    }
}
