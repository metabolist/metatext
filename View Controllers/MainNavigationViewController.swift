// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import SwiftUI
import ViewModels

final class MainNavigationViewController: UITabBarController {
    private let viewModel: NavigationViewModel
    private let rootViewModel: RootViewModel
    private var cancellables = Set<AnyCancellable>()

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

        viewModel.$presentedNewStatusViewModel.sink { [weak self] in
            if let newStatusViewModel = $0 {
                self?.presentNewStatus(newStatusViewModel: newStatusViewModel)
            } else {
                self?.dismissNewStatus()
            }
        }
        .store(in: &cancellables)

        viewModel.$presentingSecondaryNavigation.sink { [weak self] in
            if $0 {
                self?.presentSecondaryNavigation()
            } else {
                self?.dismissSecondaryNavigation()
            }
        }
        .store(in: &cancellables)

        viewModel.identityContext.$identity.map(\.pending)
            .removeDuplicates()
            .sink { [weak self] in self?.setupViewControllers(pending: $0) }
            .store(in: &cancellables)

        viewModel.navigations
            .sink { [weak self] in self?.handle(navigation: $0) }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIScene.willEnterForegroundNotification)
            .sink { [weak self] _ in self?.viewModel.refreshIdentity() }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.refreshIdentity()
    }
}

private extension MainNavigationViewController {
    static let secondaryNavigationViewTag = UUID().hashValue
    static let newStatusViewTag = UUID().hashValue

    func setupViewControllers(pending: Bool) {
        var controllers: [UIViewController] = [
            TimelinesViewController(
                viewModel: viewModel,
                rootViewModel: rootViewModel)
        ]

        if viewModel.identityContext.identity.authenticated && !pending {
            tabBar.isHidden = false
            controllers.append(ExploreViewController(viewModel: viewModel.exploreViewModel(),
                                                     rootViewModel: rootViewModel))
            controllers.append(NotificationsViewController(viewModel: viewModel, rootViewModel: rootViewModel))

            let conversationsViewController = TableViewController(
                viewModel: viewModel.conversationsViewModel(),
                rootViewModel: rootViewModel)

            conversationsViewController.tabBarItem = NavigationViewModel.Tab.messages.tabBarItem
            conversationsViewController.navigationItem.title = NavigationViewModel.Tab.messages.title

            controllers.append(conversationsViewController)

            setupNewStatusButton()
        } else {
            tabBar.isHidden = true
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

            self.viewModel.presentedNewStatusViewModel =
                self.rootViewModel.newStatusViewModel(identityContext: self.viewModel.identityContext)
        })

        view.addSubview(newStatusButtonView)
        newStatusButtonView.translatesAutoresizingMaskIntoConstraints = false

        viewModel.identityContext.$appPreferences.map(\.statusWord).removeDuplicates().sink {
            switch $0 {
            case .toot:
                newStatusButtonView.button.accessibilityLabel =
                    NSLocalizedString("compose-button.accessibility-label.toot", comment: "")
            case.post:
                newStatusButtonView.button.accessibilityLabel =
                    NSLocalizedString("compose-button.accessibility-label.post", comment: "")
            }
        }
        .store(in: &cancellables)

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
        hostingController.navigationItem.titleView = SecondaryNavigationTitleView(viewModel: viewModel)

        let navigationController = UINavigationController(rootViewController: hostingController)

        navigationController.view.tag = Self.secondaryNavigationViewTag

        present(navigationController, animated: true)
    }

    func dismissSecondaryNavigation() {
        if presentedViewController?.view.tag == Self.secondaryNavigationViewTag {
            dismiss(animated: true)
        }
    }

    func presentNewStatus(newStatusViewModel: NewStatusViewModel) {
        let newStatusViewController =  NewStatusViewController(viewModel: newStatusViewModel,
                                                               rootViewModel: rootViewModel)
        let navigationController = UINavigationController(rootViewController: newStatusViewController)

        if UIDevice.current.userInterfaceIdiom == .phone {
            navigationController.modalPresentationStyle = .overFullScreen
        } else {
            navigationController.isModalInPresentation = true
        }

        navigationController.view.tag = Self.newStatusViewTag

        present(navigationController, animated: true)
    }

    func dismissNewStatus() {
        if presentedViewController?.view.tag == Self.newStatusViewTag {
            dismiss(animated: true)
        }
    }

    func handle(navigation: Navigation) {
        let vc: UIViewController

        switch navigation {
        case let .collection(collectionService):
            vc = TableViewController(
                viewModel: CollectionItemsViewModel(
                    collectionService: collectionService,
                    identityContext: viewModel.identityContext),
                rootViewModel: rootViewModel)
        case let .profile(profileService):
            vc = ProfileViewController(
                viewModel: ProfileViewModel(
                    profileService: profileService,
                    identityContext: viewModel.identityContext),
                rootViewModel: rootViewModel,
                identityContext: viewModel.identityContext,
                parentNavigationController: nil)
        default:
            return
        }

        selectedViewController?.show(vc, sender: self)
    }
}
