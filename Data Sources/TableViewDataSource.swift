// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class TableViewDataSource: UITableViewDiffableDataSource<CollectionSection.Identifier, CollectionItem> {
    private let updateQueue =
        DispatchQueue(label: "com.metabolist.metatext.collection-data-source.update-queue")

    init(tableView: UITableView, viewModelProvider: @escaping (IndexPath) -> CollectionItemViewModel) {
        for cellClass in CollectionItem.cellClasses {
            tableView.register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
        }

        super.init(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: item.cellClass),
                for: indexPath)

            switch (cell, viewModelProvider(indexPath)) {
            case let (statusCell as StatusTableViewCell, statusViewModel as StatusViewModel):
                statusCell.viewModel = statusViewModel
            case let (accountCell as AccountTableViewCell, accountViewModel as AccountViewModel):
                accountCell.viewModel = accountViewModel
            case let (loadMoreCell as LoadMoreTableViewCell, loadMoreViewModel as LoadMoreViewModel):
                loadMoreCell.viewModel = loadMoreViewModel
            case let (notificationCell as NotificationTableViewCell, notificationViewModel as NotificationViewModel):
                notificationCell.viewModel = notificationViewModel
            case let (conversationCell as ConversationTableViewCell, conversationViewModel as ConversationViewModel):
                conversationCell.viewModel = conversationViewModel
            case let (tagCell as TagTableViewCell, tagViewModel as TagViewModel):
                tagCell.viewModel = tagViewModel
            case let (_, moreResultsViewModel as MoreResultsViewModel):
                var configuration = cell.defaultContentConfiguration()

                configuration.text = moreResultsViewModel.scope.moreDescription

                cell.contentConfiguration = configuration
                cell.accessoryType = .disclosureIndicator
            default:
                break
            }

            return cell
        }
    }

    override func apply(_ snapshot: NSDiffableDataSourceSnapshot<CollectionSection.Identifier, CollectionItem>,
                        animatingDifferences: Bool = true,
                        completion: (() -> Void)? = nil) {
        updateQueue.async {
            super.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let currentSnapshot = snapshot()
        let section = currentSnapshot.sectionIdentifiers[section]

        if currentSnapshot.numberOfItems(inSection: section) > 0,
           let localizedStringKey = section.titleLocalizedStringKey {
            return NSLocalizedString(localizedStringKey, comment: "")
        }

        return nil
    }
}

extension TableViewDataSource {
    func indexPath(itemId: CollectionItem.Id) -> IndexPath? {
        guard let item = snapshot().itemIdentifiers.first(where: { $0.itemId == itemId }) else { return nil }

        return indexPath(for: item)
    }
}
