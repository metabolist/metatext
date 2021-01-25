// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class ExploreViewController: UICollectionViewController {
    private let viewModel: ExploreViewModel
    private let rootViewModel: RootViewModel
    private let identification: Identification

    init(viewModel: ExploreViewModel, rootViewModel: RootViewModel, identification: Identification) {
        self.viewModel = viewModel
        self.rootViewModel = rootViewModel
        self.identification = identification

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
            identification: identification,
            insetBottom: false,
            parentNavigationController: navigationController)

        let searchController = UISearchController(searchResultsController: searchResultsController)

        searchController.searchBar.scopeButtonTitles = SearchViewModel.Scope.allCases.map(\.title)
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
    }
}

extension ExploreViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let scope = SearchViewModel.Scope(rawValue: searchController.searchBar.selectedScopeButtonIndex) {
            viewModel.searchViewModel.scope = scope
        }

        viewModel.searchViewModel.query = searchController.searchBar.text ?? ""
    }
}
