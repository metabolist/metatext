// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Mastodon
import SwiftUI
import ViewModels

final class ProfileViewController: TableViewController {
    private let viewModel: ProfileViewModel
    private var cancellables = Set<AnyCancellable>()

    required init(
        viewModel: ProfileViewModel,
        rootViewModel: RootViewModel,
        identityContext: IdentityContext,
        parentNavigationController: UINavigationController?) {
        self.viewModel = viewModel

        super.init(
            viewModel: viewModel,
            rootViewModel: rootViewModel,
            parentNavigationController: parentNavigationController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initial size is to avoid unsatisfiable constraint warning
        let accountHeaderView = AccountHeaderView(frame: .init(origin: .zero, size: .init(width: 300, height: 300)))

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
    // swiftlint:disable:next function_body_length
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

        actions.append(UIAction(
            title: NSLocalizedString("report", comment: ""),
            image: UIImage(systemName: "flag"),
            attributes: .destructive) { [weak self] _ in
            guard let self = self,
                  let reportViewModel = self.viewModel.accountViewModel?.reportViewModel()
            else { return }

            self.report(reportViewModel: reportViewModel)
        })

        if relationship.blocking {
            actions.append(UIAction(
                title: NSLocalizedString("account.unblock", comment: ""),
                image: UIImage(systemName: "slash.circle"),
                attributes: .destructive) { [weak self] _ in
                self?.confirm(message: String.localizedStringWithFormat(
                                NSLocalizedString("account.unblock.confirm-%@", comment: ""),
                                accountViewModel.accountName)) {
                    accountViewModel.unblock()
                }
                })
        } else {
            actions.append(UIAction(
                title: NSLocalizedString("account.block", comment: ""),
                image: UIImage(systemName: "slash.circle"),
                attributes: .destructive) { [weak self] _ in
                self?.confirm(message: String.localizedStringWithFormat(
                                NSLocalizedString("account.block.confirm-%@", comment: ""),
                                accountViewModel.accountName)) {
                    accountViewModel.block()
                }
                })
        }

        if !accountViewModel.isLocal, let domain = accountViewModel.domain {
            if relationship.domainBlocking {
                actions.append(UIAction(
                    title: String.localizedStringWithFormat(
                        NSLocalizedString("account.domain-unblock-%@", comment: ""),
                        domain),
                    image: UIImage(systemName: "slash.circle"),
                    attributes: .destructive) { [weak self] _ in
                    self?.confirm(message: String.localizedStringWithFormat(
                                    NSLocalizedString("account.domain-unblock.confirm-%@", comment: ""),
                                    domain)) {
                        accountViewModel.domainUnblock()
                    }
                })
            } else {
                actions.append(UIAction(
                    title: String.localizedStringWithFormat(
                        NSLocalizedString("account.domain-block-%@", comment: ""),
                        domain),
                    image: UIImage(systemName: "slash.circle"),
                    attributes: .destructive) { [weak self] _ in
                    self?.confirm(message: String.localizedStringWithFormat(
                                    NSLocalizedString("account.domain-block.confirm-%@", comment: ""),
                                    domain)) {
                        accountViewModel.domainBlock()
                    }
                    })
            }
        }

        return UIMenu(children: actions)
    }

    func confirm(message: String, action: @escaping () -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .destructive) { _ in
            action()
        }

        alertController.addAction(cancelAction)
        alertController.addAction(okAction)

        present(alertController, animated: true)
    }
}
