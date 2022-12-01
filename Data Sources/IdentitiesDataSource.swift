// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

enum IdentitiesSection: Hashable {
    case add
    case identities(String)
}

enum IdentitiesItem: Hashable {
    case add
    case identity(Identity)
}

final class IdentitiesDataSource: UITableViewDiffableDataSource<IdentitiesSection, IdentitiesItem> {
    private let updateQueue =
        DispatchQueue(label: "com.metabolist.metatext.identities-data-source.update-queue")
    private var cancellables = Set<AnyCancellable>()

    init(tableView: UITableView,
         publisher: AnyPublisher<[Identity], Never>,
         viewModelProvider: @escaping (Identity) -> IdentityViewModel) {

        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: String(describing: UITableViewCell.self))
        tableView.register(IdentityTableViewCell.self,
                           forCellReuseIdentifier: String(describing: IdentityTableViewCell.self))

        super.init(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: item.cellReuseIdentifier,
                                                     for: indexPath)

            switch item {
            case .add:
                var configuration = cell.defaultContentConfiguration()

                configuration.text = NSLocalizedString("add", comment: "")
                configuration.image = UIImage(systemName: "plus.circle.fill")
                cell.contentConfiguration = configuration
            case let .identity(identity):
                let viewModel = viewModelProvider(identity)

                (cell as? IdentityTableViewCell)?.viewModel = viewModel
                cell.accessoryType = identity.id == viewModel.identityContext.identity.id ? .checkmark : .none
            }

            return cell
        }

        publisher
            .sink { [weak self] in self?.update(identities: $0) }
            .store(in: &cancellables)
    }

    override func apply(_ snapshot: NSDiffableDataSourceSnapshot<IdentitiesSection, IdentitiesItem>,
                        animatingDifferences: Bool = true,
                        completion: (() -> Void)? = nil) {
        updateQueue.async {
            super.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let currentSnapshot = snapshot()
        let section = currentSnapshot.sectionIdentifiers[section]

        if currentSnapshot.numberOfItems(inSection: section) > 0, case let .identities(title) = section {
            return title
        }

        return nil
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        itemIdentifier(for: indexPath) != .add
    }
}

private extension IdentitiesDataSource {
    private func update(identities: [Identity]) {
        var newSnapshot = NSDiffableDataSourceSnapshot<IdentitiesSection, IdentitiesItem>()
        let sections = [
            (section: IdentitiesSection.identities(NSLocalizedString("identities.accounts", comment: "")),
             identities: identities.filter { $0.authenticated && !$0.pending }.map(IdentitiesItem.identity)),
            (section: IdentitiesSection.identities(NSLocalizedString("identities.browsing", comment: "")),
             identities: identities.filter { !$0.authenticated && !$0.pending }.map(IdentitiesItem.identity)),
             (section: IdentitiesSection.identities(NSLocalizedString("identities.pending", comment: "")),
             identities: identities.filter { $0.pending }.map(IdentitiesItem.identity))
        ]
        .filter { !$0.identities.isEmpty }

        newSnapshot.appendSections([.add] + sections.map(\.section))
        newSnapshot.appendItems([.add], toSection: .add)

        for section in sections {
            newSnapshot.appendItems(section.identities, toSection: section.section)
        }

        apply(newSnapshot, animatingDifferences: !snapshot().sectionIdentifiers.filter { $0 != .add }.isEmpty)
    }
}

private extension IdentitiesItem {
    var cellReuseIdentifier: String {
        switch self {
        case .add:
            return String(describing: UITableViewCell.self)
        case .identity:
            return String(describing: IdentityTableViewCell.self)
        }
    }
}
