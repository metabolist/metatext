// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class ProfileViewController: TableViewController {
    private let viewModel: ProfileViewModel
    private var cancellables = Set<AnyCancellable>()

    required init(viewModel: ProfileViewModel, identification: Identification) {
        self.viewModel = viewModel

        super.init(viewModel: viewModel, identification: identification)
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

        viewModel.imagePresentations.sink { [weak self] in
            guard let self = self else { return }

            let imagePageViewController = ImagePageViewController(imageURL: $0)
            let imageNavigationController = ImageNavigationController(imagePageViewController: imagePageViewController)

            imageNavigationController.transitionController.fromDelegate = self
            self.transitionViewTag = $0.hashValue

            self.present(imageNavigationController, animated: true)
        }
        .store(in: &cancellables)

        tableView.tableHeaderView = accountHeaderView
    }
}
