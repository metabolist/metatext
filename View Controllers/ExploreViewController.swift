// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class ExploreViewController: UICollectionViewController {
    private let viewModel: ExploreViewModel
    private let rootViewModel: RootViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var dataSource: ExploreDataSource = {
        .init(collectionView: collectionView, viewModel: viewModel)
    }()

    init(viewModel: ExploreViewModel, rootViewModel: RootViewModel) {
        self.viewModel = viewModel
        self.rootViewModel = rootViewModel

        super.init(collectionViewLayout: Self.layout())

        tabBarItem = UITabBarItem(
            title: NSLocalizedString("main-navigation.explore", comment: ""),
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = dataSource
        collectionView.backgroundColor = .systemBackground
        collectionView.contentInset.bottom = Self.bottomInset
        collectionView.isAccessibilityElement = false
        collectionView.shouldGroupAccessibilityChildren = true
        clearsSelectionOnViewWillAppear = true

        collectionView.refreshControl = UIRefreshControl()
        collectionView.refreshControl?.addAction(
            UIAction { [weak self] _ in
                self?.viewModel.refresh() },
            for: .valueChanged)

        navigationItem.title = NSLocalizedString("main-navigation.explore", comment: "")

        let searchResultsController = TableViewController(
            viewModel: viewModel.searchViewModel,
            rootViewModel: rootViewModel,
            insetBottom: false,
            parentNavigationController: navigationController)

        let searchController = UISearchController(searchResultsController: searchResultsController)

        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController

        viewModel.identityContext.$appPreferences.sink { appPreferences in
            searchController.searchBar.scopeButtonTitles = SearchScope.allCases.map {
                $0.title(statusWord: appPreferences.statusWord)
            }
        }
        .store(in: &cancellables)

        viewModel.events.sink { [weak self] in self?.handle(event: $0) }.store(in: &cancellables)

        viewModel.$loading.sink { [weak self] in
            guard let self = self else { return }

            let refreshControlVisibile = self.collectionView.refreshControl?.isRefreshing ?? false

            if !$0, refreshControlVisibile {
                self.collectionView.refreshControl?.endRefreshing()
            }
        }
        .store(in: &cancellables)

        viewModel.searchViewModel.events.sink { [weak self] in
            if case let .navigation(navigation) = $0,
               case let .searchScope(scope) = navigation {
                searchController.searchBar.selectedScopeButtonIndex = scope.rawValue
                self?.updateSearchResults(for: searchController)
            }
        }
        .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.refresh()
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        dataSource.itemIdentifier(for: indexPath) != .instance
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        viewModel.select(item: item)
    }
}

extension ExploreViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let scope = SearchScope(rawValue: searchController.searchBar.selectedScopeButtonIndex) {
            if scope != viewModel.searchViewModel.scope,
               let scrollView = searchController.searchResultsController?.view as? UIScrollView {
                scrollView.setContentOffset(.init(x: 0, y: -scrollView.safeAreaInsets.top), animated: false)
            }

            viewModel.searchViewModel.scope = scope
        }

        viewModel.searchViewModel.query = searchController.searchBar.text ?? ""
    }
}

extension ExploreViewController: ScrollableToTop {
    func scrollToTop(animated: Bool) {
        collectionView.scrollToTop(animated: animated)
    }
}

private extension ExploreViewController {
    static let bottomInset: CGFloat = .newStatusButtonDimension + .defaultSpacing * 4

    static func layout() -> UICollectionViewLayout {
        var listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)

        listConfiguration.headerMode = .supplementary

        return UICollectionViewCompositionalLayout(
            sectionProvider: {
                let section = NSCollectionLayoutSection.list(using: listConfiguration, layoutEnvironment: $1)

                if UIDevice.current.userInterfaceIdiom == .pad {
                    section.contentInsetsReference = .readableContent
                }

                return section
            })
    }

    func handle(event: ExploreViewModel.Event) {
        switch event {
        case let .navigation(navigation):
            handle(navigation: navigation)
        }
    }

    func handle(navigation: Navigation) {
        switch navigation {
        case let .collection(collectionService):
            let vc = TableViewController(
                viewModel: CollectionItemsViewModel(
                    collectionService: collectionService,
                    identityContext: viewModel.identityContext),
                rootViewModel: rootViewModel,
                parentNavigationController: nil)

                show(vc, sender: self)
        default:
            break
        }
    }
}
