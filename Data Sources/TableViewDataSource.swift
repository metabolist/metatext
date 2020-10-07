// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

class TableViewDataSource: UITableViewDiffableDataSource<Int, CollectionItemIdentifier> {
    private let updateQueue =
        DispatchQueue(label: "com.metabolist.metatext.collection-data-source.update-queue")

    init(tableView: UITableView, viewModelProvider: @escaping (IndexPath) -> CollectionItemViewModel) {
        for kind in CollectionItemIdentifier.Kind.allCases {
            tableView.register(kind.cellClass, forCellReuseIdentifier: String(describing: kind.cellClass))
        }

        super.init(tableView: tableView) { tableView, indexPath, identifier in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: identifier.kind.cellClass),
                for: indexPath)

            switch (cell, viewModelProvider(indexPath)) {
            case let (statusListCell as StatusListCell, statusViewModel as StatusViewModel):
                statusListCell.viewModel = statusViewModel
            case let (accountListCell as AccountListCell, accountViewModel as AccountViewModel):
                accountListCell.viewModel = accountViewModel
            case let (loadMoreCell as LoadMoreCell, loadMoreViewModel as LoadMoreViewModel):
                loadMoreCell.viewModel = loadMoreViewModel
            default:
                break
            }

            return cell
        }

        defaultRowAnimation = .none
    }

    override func apply(_ snapshot: NSDiffableDataSourceSnapshot<Int, CollectionItemIdentifier>,
                        animatingDifferences: Bool = true,
                        completion: (() -> Void)? = nil) {
        let differenceExceptShowMoreToggled = self.snapshot().itemIdentifiers.difference(
            from: snapshot.itemIdentifiers,
            by: CollectionItemIdentifier.isSameExceptShowMoreToggled(lhs:rhs:))
        let animated = snapshot.itemIdentifiers.count > 0 && differenceExceptShowMoreToggled.count == 0

        updateQueue.async {
            super.apply(snapshot, animatingDifferences: animated, completion: completion)
        }
    }
}
