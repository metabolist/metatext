// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class ProfileViewController: TableViewController {
    private let viewModel: ProfileViewModel
    private var cancellables = Set<AnyCancellable>()

    required init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel

        super.init(viewModel: viewModel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initial size is to avoid unsatisfiable constraint warning
        let accountHeaderView = AccountHeaderView(frame: .init(origin: .zero, size: .init(width: 100, height: 100)))

        accountHeaderView.viewModel = viewModel

        viewModel.$accountViewModel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                accountHeaderView.viewModel = self?.viewModel
                self?.sizeTableHeaderFooterViews()
            }
            .store(in: &cancellables)

        tableView.tableHeaderView = accountHeaderView
    }
}
