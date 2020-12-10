// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import ServiceLayer
import UIKit
import ViewModels

@objc(ShareExtensionNavigationViewController)
class ShareExtensionNavigationViewController: UINavigationController {
    private let viewModel = ShareExtensionNavigationViewModel(
        environment: .live(
            userNotificationCenter: .current(),
            reduceMotion: { UIAccessibility.isReduceMotionEnabled }))
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        let newStatusViewModel: NewStatusViewModel

        do {
            newStatusViewModel = try viewModel.newStatusViewModel()
        } catch {
            setViewControllers([ShareErrorViewController(error: error)], animated: false)

            return
        }

        setViewControllers(
            [NewStatusViewController(viewModel: newStatusViewModel, isShareExtension: true)],
            animated: false)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
