// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import Mastodon
import UIKit
import ViewModels

enum AutocompleteSection: Int, Hashable {
    case search
    case emoji
}

enum AutocompleteItem: Hashable {
    case account(Account)
    case tag(Tag)
    case emoji(PickerEmoji)
}

final class AutocompleteDataSource: UICollectionViewDiffableDataSource<AutocompleteSection, AutocompleteItem> {
    @Published private var searchViewModel: SearchViewModel
    @Published private var emojiPickerViewModel: EmojiPickerViewModel

    private let updateQueue =
        DispatchQueue(label: "com.metabolist.metatext.autocomplete-data-source.update-queue")
    private var cancellables = Set<AnyCancellable>()

    init(collectionView: UICollectionView,
         queryPublisher: AnyPublisher<String?, Never>,
         parentViewModel: NewStatusViewModel) {
        searchViewModel = SearchViewModel(identityContext: parentViewModel.identityContext)
        emojiPickerViewModel = EmojiPickerViewModel(identityContext: parentViewModel.identityContext, queryOnly: true)

        let registration = UICollectionView.CellRegistration<AutocompleteItemCollectionViewCell, AutocompleteItem> {
            $0.item = $2
            $0.identityContext = parentViewModel.identityContext
        }

        let emojiRegistration = UICollectionView.CellRegistration<EmojiCollectionViewCell, PickerEmoji> {
            $0.viewModel = EmojiViewModel(emoji: $2, identityContext: parentViewModel.identityContext)
        }

        super.init(collectionView: collectionView) {
            if case let .emoji(emoji) = $2 {
                return $0.dequeueConfiguredReusableCell(using: emojiRegistration, for: $1, item: emoji)
            } else {
                return $0.dequeueConfiguredReusableCell(using: registration, for: $1, item: $2)
            }
        }

        queryPublisher
            .replaceNil(with: "")
            .removeDuplicates()
            .combineLatest($searchViewModel, $emojiPickerViewModel)
            .sink(receiveValue: Self.combine(query:searchViewModel:emojiPickerViewModel:))
            .store(in: &cancellables)

        $searchViewModel.map(\.updates)
            .switchToLatest()
            .combineLatest($emojiPickerViewModel.map(\.$emoji).switchToLatest())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.apply(searchViewModelUpdate: $0, emojiSections: $1) }
            .store(in: &cancellables)

        parentViewModel.$identityContext
            .dropFirst()
            .sink { [weak self] in
                guard let self = self else { return }

                self.searchViewModel = SearchViewModel(identityContext: $0)
                self.emojiPickerViewModel = EmojiPickerViewModel(identityContext: $0, queryOnly: true)
            }
            .store(in: &cancellables)
    }

    override func apply(_ snapshot: NSDiffableDataSourceSnapshot<AutocompleteSection, AutocompleteItem>,
                        animatingDifferences: Bool = true,
                        completion: (() -> Void)? = nil) {
        updateQueue.async {
            super.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
        }
    }
}

extension AutocompleteDataSource {
    func updateUse(emoji: PickerEmoji) {
        emojiPickerViewModel.updateUse(emoji: emoji)
    }
}

private extension AutocompleteDataSource {
    static func combine(query: String, searchViewModel: SearchViewModel, emojiPickerViewModel: EmojiPickerViewModel) {
        if query.starts(with: ":") {
            searchViewModel.query = ""
            emojiPickerViewModel.query = String(query.dropFirst())
        } else {
            if query.starts(with: "@") {
                searchViewModel.scope = .accounts
            } else if query.starts(with: "#") {
                searchViewModel.scope = .tags
            }

            searchViewModel.query = String(query.dropFirst())
            emojiPickerViewModel.query = ""
        }
    }

    func apply(searchViewModelUpdate: CollectionUpdate, emojiSections: [PickerEmoji.Category: [PickerEmoji]]) {
        var newSnapshot = NSDiffableDataSourceSnapshot<AutocompleteSection, AutocompleteItem>()
        let items: [AutocompleteItem] = searchViewModelUpdate.sections.map(\.items).reduce([], +).compactMap {
            switch $0 {
            case let .account(account, _, _):
                return .account(account)
            case let .tag(tag):
                return .tag(tag)
            default:
                return nil
            }
        }
        let emojis = emojiSections.sorted { $0.0 < $1.0 }.map(\.value).reduce([], +).map(AutocompleteItem.emoji)

        newSnapshot.appendSections([.search])

        if !items.isEmpty {
            newSnapshot.appendItems(items, toSection: .search)
        } else if !emojis.isEmpty {
            newSnapshot.appendSections([.emoji])
            newSnapshot.appendItems(emojis, toSection: .emoji)
        }

        apply(newSnapshot, animatingDifferences: !UIAccessibility.isReduceMotionEnabled) {
            // animation causes issue with custom emoji images requiring reload
            newSnapshot.reloadItems(newSnapshot.itemIdentifiers)
            self.apply(newSnapshot, animatingDifferences: false)
        }
    }
}
