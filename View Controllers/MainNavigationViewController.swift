// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import SwiftUI
import ViewModels

final class MainNavigationViewController: UITabBarController {
    private let viewModel: NavigationViewModel
    private let rootViewModel: RootViewModel
    private var cancellables = Set<AnyCancellable>()
    private weak var presentedSecondaryNavigation: UINavigationController?

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

        setupViewControllers()

        if viewModel.identityContext.identity.authenticated {
            setupNewStatusButton()
        }

        viewModel.$presentingSecondaryNavigation.sink { [weak self] in
            if $0 {
                self?.presentSecondaryNavigation()
            } else {
                self?.dismissSecondaryNavigation()
            }
        }
        .store(in: &cancellables)

        viewModel.timelineNavigations
            .sink { [weak self] _ in self?.selectedIndex = 0 }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.refreshIdentity()
    }
}

private extension MainNavigationViewController {
    func setupViewControllers() {
        var controllers: [UIViewController] = [
            TimelinesViewController(
                viewModel: viewModel,
                rootViewModel: rootViewModel),
            ExploreViewController(
                viewModel: viewModel.exploreViewModel,
                rootViewModel: rootViewModel)
        ]

        if viewModel.identityContext.identity.authenticated {
            controllers.append(NotificationsViewController(viewModel: viewModel, rootViewModel: rootViewModel))
        }

        if let conversationsViewModel = viewModel.conversationsViewModel {
            let conversationsViewController = TableViewController(
                viewModel: conversationsViewModel,
                rootViewModel: rootViewModel)

            conversationsViewController.tabBarItem = NavigationViewModel.Tab.messages.tabBarItem
            conversationsViewController.navigationItem.title = NavigationViewModel.Tab.messages.title

            controllers.append(conversationsViewController)
        }

        let secondaryNavigationButton = SecondaryNavigationButton(viewModel: viewModel, rootViewModel: rootViewModel)

        for controller in controllers {
            controller.navigationItem.leftBarButtonItem = secondaryNavigationButton
        }

        viewControllers = controllers.map(UINavigationController.init(rootViewController:))
    }

    func setupNewStatusButton() {
        let newStatusButtonView = NewStatusButtonView(primaryAction: UIAction { [weak self] _ in
            guard let self = self else { return }
            let newStatusViewModel = self.rootViewModel.newStatusViewModel(
                identityContext: self.viewModel.identityContext)
            let newStatusViewController = NewStatusViewController(viewModel: newStatusViewModel)
            let newStatusNavigationController = UINavigationController(rootViewController: newStatusViewController)

            if UIDevice.current.userInterfaceIdiom == .phone {
                newStatusNavigationController.modalPresentationStyle = .overFullScreen
            } else {
                newStatusNavigationController.isModalInPresentation = true
            }

            self.present(newStatusNavigationController, animated: true)
        })

        view.addSubview(newStatusButtonView)
        newStatusButtonView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            newStatusButtonView.widthAnchor.constraint(equalToConstant: .newStatusButtonDimension),
            newStatusButtonView.heightAnchor.constraint(equalToConstant: .newStatusButtonDimension),
            newStatusButtonView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -.defaultSpacing * 2),
            newStatusButtonView.bottomAnchor.constraint(equalTo: tabBar.topAnchor, constant: -.defaultSpacing * 2)
        ])
    }

    func presentSecondaryNavigation() {
        let secondaryNavigationView = SecondaryNavigationView(viewModel: viewModel)
            .environmentObject(rootViewModel)
        let hostingController = UIHostingController(rootView: secondaryNavigationView)

        hostingController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in self?.viewModel.presentingSecondaryNavigation = false })

        let navigationController = UINavigationController(rootViewController: hostingController)

        presentedSecondaryNavigation = navigationController
        present(navigationController, animated: true)
    }

    func dismissSecondaryNavigation() {
        if presentedViewController == presentedSecondaryNavigation {
            dismiss(animated: true)
        }
    }
}
