// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Mastodon
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
            .sink { [weak self] in
                guard let self = self else { return }

                accountHeaderView.viewModel = self.viewModel
                self.sizeTableHeaderFooterViews()

                if let accountViewModel = $0,
                   let relationship = accountViewModel.relationship {
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                        image: UIImage(systemName: "ellipsis.circle"),
                        menu: self.menu(accountViewModel: accountViewModel, relationship: relationship))
                }
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.fetchProfile()
            .sink { _ in }
            .store(in: &cancellables)
    }
}

private extension ProfileViewController {
    func menu(accountViewModel: AccountViewModel, relationship: Relationship) -> UIMenu {
        var actions = [UIAction]()

        if relationship.following {
            if relationship.showingReblogs {
                actions.append(UIAction(
                    title: NSLocalizedString("account.hide-reblogs", comment: ""),
                    image: UIImage(systemName: "arrow.2.squarepath")) { _ in
                    accountViewModel.hideReblogs()
                })
            } else {
                actions.append(UIAction(
                    title: NSLocalizedString("account.show-reblogs", comment: ""),
                    image: UIImage(systemName: "arrow.2.squarepath")) { _ in
                    accountViewModel.showReblogs()
                })
            }
        }

        if relationship.muting {
            actions.append(UIAction(
                title: NSLocalizedString("account.unmute", comment: ""),
                image: UIImage(systemName: "speaker")) { _ in
                accountViewModel.unmute()
            })
        } else {
            actions.append(UIAction(
                title: NSLocalizedString("account.mute", comment: ""),
                image: UIImage(systemName: "speaker.slash")) { _ in
                accountViewModel.mute()
            })
        }

        if relationship.blocking {
            actions.append(UIAction(
                title: NSLocalizedString("account.unblock", comment: ""),
                image: UIImage(systemName: "slash.circle")) { _ in
                accountViewModel.unblock()
            })
        } else {
            actions.append(UIAction(
                title: NSLocalizedString("account.block", comment: ""),
                image: UIImage(systemName: "slash.circle"),
                attributes: .destructive) { _ in
                accountViewModel.block()
            })
        }

        return UIMenu(children: actions)
    }
}
