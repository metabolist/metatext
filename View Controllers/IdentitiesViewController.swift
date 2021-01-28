// Copyright © 2021 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

final class IdentitiesViewController: UITableViewController {
    private let viewModel: IdentitiesViewModel
    private let rootViewModel: RootViewModel

    private lazy var dataSource: IdentitiesDataSource = {
        .init(tableView: tableView,
              publisher: viewModel.$identities.eraseToAnyPublisher(),
              viewModelProvider: viewModel.viewModel(identity:),
              deleteAction: { [weak self] in self?.rootViewModel.deleteIdentity(id: $0.id) })
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
        if case let .identitiy(identityViewModel) = dataSource.itemIdentifier(for: indexPath) {
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
        case let .identitiy(identityViewModel):
            rootViewModel.identitySelected(id: identityViewModel.id)
        }
    }
}
