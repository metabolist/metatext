// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class MainNavigationViewController: UITabBarController {
    private let viewModel: NavigationViewModel
    private let rootViewModel: RootViewModel

    init(viewModel: NavigationViewModel, rootViewModel: RootViewModel) {
        self.viewModel = viewModel
        self.rootViewModel = rootViewModel

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let timelinesViewController = TimelinesViewController(
            viewModel: viewModel,
            rootViewModel: rootViewModel)
        let timelinesNavigationController = UINavigationController(rootViewController: timelinesViewController)

        if let notificationsViewModel = viewModel.notificationsViewModel,
           let conversationsViewModel = viewModel.conversationsViewModel {
            let notificationsViewController = TableViewController(
                viewModel: notificationsViewModel,
                rootViewModel: rootViewModel,
                identification: viewModel.identification)

            notificationsViewController.tabBarItem = NavigationViewModel.Tab.notifications.tabBarItem

            let notificationsNavigationViewController = UINavigationController(
                rootViewController: notificationsViewController)

            let conversationsViewController = TableViewController(
                viewModel: conversationsViewModel,
                rootViewModel: rootViewModel,
                identification: viewModel.identification)

            conversationsViewController.tabBarItem = NavigationViewModel.Tab.messages.tabBarItem
            conversationsViewController.navigationItem.title = NavigationViewModel.Tab.messages.title

            let conversationsNavigationViewController = UINavigationController(
                rootViewController: conversationsViewController)

            viewControllers = [
                timelinesNavigationController,
                notificationsNavigationViewController,
                conversationsNavigationViewController
            ]
        } else {
            viewControllers = [
                timelinesNavigationController
            ]
        }
    }
}
