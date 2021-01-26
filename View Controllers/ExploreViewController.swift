// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class ExploreViewController: UICollectionViewController {
    private let viewModel: ExploreViewModel
    private let rootViewModel: RootViewModel
    private let identityContext: IdentityContext
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: ExploreViewModel, rootViewModel: RootViewModel, identityContext: IdentityContext) {
        self.viewModel = viewModel
        self.rootViewModel = rootViewModel
        self.identityContext = identityContext

        super.init(collectionViewLayout: UICollectionViewFlowLayout())

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

        navigationItem.title = NSLocalizedString("main-navigation.explore", comment: "")

        let searchResultsController = TableViewController(
            viewModel: viewModel.searchViewModel,
            rootViewModel: rootViewModel,
            identityContext: identityContext,
            insetBottom: false,
            parentNavigationController: navigationController)

        let searchController = UISearchController(searchResultsController: searchResultsController)

        searchController.searchBar.scopeButtonTitles = SearchScope.allCases.map(\.title)
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController

        viewModel.searchViewModel.events.sink { [weak self] in
            if case let .navigation(navigation) = $0,
               case let .searchScope(scope) = navigation {
                searchController.searchBar.selectedScopeButtonIndex = scope.rawValue
                self?.updateSearchResults(for: searchController)
            }
        }
        .store(in: &cancellables)
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
