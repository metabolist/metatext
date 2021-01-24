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
            case let (statusListCell as StatusListCell, statusViewModel as StatusViewModel):
                statusListCell.viewModel = statusViewModel
            case let (accountListCell as AccountListCell, accountViewModel as AccountViewModel):
                accountListCell.viewModel = accountViewModel
            case let (loadMoreCell as LoadMoreCell, loadMoreViewModel as LoadMoreViewModel):
                loadMoreCell.viewModel = loadMoreViewModel
            case let (notificationListCell as NotificationListCell, notificationViewModel as NotificationViewModel):
                notificationListCell.viewModel = notificationViewModel
            case let (conversationListCell as ConversationListCell, conversationViewModel as ConversationViewModel):
                conversationListCell.viewModel = conversationViewModel
            case let (tagTableViewCell as TagTableViewCell, tagViewModel as TagViewModel):
                tagTableViewCell.viewModel = tagViewModel
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
