// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import ServiceLayer
import UIKit
import ViewModels

@objc(ShareExtensionNavigationViewController)
class ShareExtensionNavigationViewController: UINavigationController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        let vm: NewStatusViewModel

        do {
            vm = try newStatusViewModel()
        } catch {
            setViewControllers([ShareErrorViewController(error: error)], animated: false)

            return
        }

        setViewControllers([NewStatusViewController(viewModel: vm)], animated: false)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ShareExtensionNavigationViewController {
    func newStatusViewModel() throws -> NewStatusViewModel {
        let environment = AppEnvironment.live(
            userNotificationCenter: .current(),
            reduceMotion: { UIAccessibility.isReduceMotionEnabled })
        let allIdentitiesService = try AllIdentitiesService(environment: environment)

        var id: Identity.Id?

        _ = allIdentitiesService.immediateMostRecentlyUsedIdentityIdPublisher()
            .sink { _ in } receiveValue: { id = $0 }

        guard let idd = id else { throw ShareExtensionError.noAccountFound }

        let newStatusService = try allIdentitiesService.identityService(id: idd).newStatusService()

        return NewStatusViewModel(service: newStatusService)
    }
}
