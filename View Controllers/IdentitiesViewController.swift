// Copyright © 2021 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

final class IdentitiesViewController: UITableViewController {
    private let viewModel: IdentitiesViewModel
    private let rootViewModel: RootViewModel

    private lazy var dataSource: IdentitiesDataSource = {
        .init(tableView: tableView,
              publisher: viewModel.$identities.eraseToAnyPublisher(),
              viewModelProvider: viewModel.viewModel(identity:))
    }()

    init(viewModel: IdentitiesViewModel, rootViewModel: RootViewModel) {
        self.viewModel = viewModel
        self.rootViewModel = rootViewModel

        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = dataSource
    }

    override func didMove(toParent parent: UIViewController?) {
        parent?.navigationItem.title = NSLocalizedString("secondary-navigation.accounts", comment: "")
        parent?.navigationItem.rightBarButtonItem = editButtonItem
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if case let .identity(identityViewModel) = dataSource.itemIdentifier(for: indexPath) {
            return identityViewModel.id != viewModel.identityContext.identity.id
        }

        return true
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .add:
            let addIdentityViewModel = rootViewModel.addIdentityViewModel()
            let addIdentityView = AddIdentityView(viewModelClosure: { addIdentityViewModel }, displayWelcome: false)
                .environmentObject(rootViewModel)
            let addIdentityViewController = UIHostingController(rootView: addIdentityView)

            show(addIdentityViewController, sender: self)
        case let .identity(identityViewModel):
            rootViewModel.identitySelected(id: identityViewModel.id)
        }
    }

    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard dataSource.itemIdentifier(for: indexPath) != .add else { return nil }

        let logOutAction = UIContextualAction(
            style: .destructive,
            title: NSLocalizedString("identities.log-out", comment: "")) { [weak self] _, _, completionHandler in
            guard let self = self, case let .identity(identity) = self.dataSource.itemIdentifier(for: indexPath) else {
                completionHandler(false)

                return
            }

            self.rootViewModel.deleteIdentity(id: identity.id)

            completionHandler(true)
        }

        return UISwipeActionsConfiguration(actions: [logOutAction])
    }
}
