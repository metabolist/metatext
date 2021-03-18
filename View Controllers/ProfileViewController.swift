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
        rootViewModel: RootViewModel?,
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

        let accountHeaderView = AccountHeaderView(viewModel: viewModel)

        viewModel.$accountViewModel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }

                accountHeaderView.viewModel = self.viewModel
                self.sizeTableHeaderFooterViews()

                if let accountViewModel = $0,
                   accountViewModel.id != self.viewModel.identityContext.identity.account?.id,
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
        var actions = [UIAction(
            title: NSLocalizedString("share", comment: ""),
            image: UIImage(systemName: "square.and.arrow.up")) { _ in
            accountViewModel.share()
        }]

        if relationship.following {
            actions.append(UIAction(
                title: NSLocalizedString("account.add-remove-lists", comment: ""),
                image: UIImage(systemName: "scroll")) { [weak self] _ in
                self?.addRemoveFromLists(accountViewModel: accountViewModel)
            })

            if relationship.showingReblogs {
                actions.append(UIAction(
                    title: NSLocalizedString("account.hide-reblogs", comment: ""),
                    image: UIImage(systemName: "arrow.2.squarepath")) { _ in
                    accountViewModel.confirmHideReblogs()
                })
            } else {
                actions.append(UIAction(
                    title: NSLocalizedString("account.show-reblogs", comment: ""),
                    image: UIImage(systemName: "arrow.2.squarepath")) { _ in
                    accountViewModel.confirmShowReblogs()
                })
            }
        }

        if relationship.muting {
            actions.append(UIAction(
                title: NSLocalizedString("account.unmute", comment: ""),
                image: UIImage(systemName: "speaker")) { _ in
                accountViewModel.confirmUnmute()
            })
        } else {
            actions.append(UIAction(
                title: NSLocalizedString("account.mute", comment: ""),
                image: UIImage(systemName: "speaker.slash")) { _ in
                accountViewModel.confirmMute()
            })
        }

        if relationship.blocking {
            actions.append(UIAction(
                title: NSLocalizedString("account.unblock", comment: ""),
                image: UIImage(systemName: "slash.circle"),
                attributes: .destructive) { _ in
                accountViewModel.confirmUnblock()
            })
        } else {
            actions.append(UIAction(
                title: NSLocalizedString("account.block", comment: ""),
                image: UIImage(systemName: "slash.circle"),
                attributes: .destructive) { _ in
                accountViewModel.confirmBlock()
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

        if !accountViewModel.isLocal, let domain = accountViewModel.domain {
            if relationship.domainBlocking {
                actions.append(UIAction(
                    title: String.localizedStringWithFormat(
                        NSLocalizedString("account.domain-unblock-%@", comment: ""),
                        domain),
                    image: UIImage(systemName: "slash.circle"),
                    attributes: .destructive) { _ in
                    accountViewModel.confirmDomainUnblock(domain: domain)
                })
            } else {
                actions.append(UIAction(
                    title: String.localizedStringWithFormat(
                        NSLocalizedString("account.domain-block-%@", comment: ""),
                        domain),
                    image: UIImage(systemName: "slash.circle"),
                    attributes: .destructive) { _ in
                    accountViewModel.confirmDomainBlock(domain: domain)
                })
            }
        }

        return UIMenu(children: actions)
    }
}
