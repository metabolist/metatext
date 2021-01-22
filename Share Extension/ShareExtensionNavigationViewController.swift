// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import ServiceLayer
import SwiftUI
import ViewModels

@objc(ShareExtensionNavigationViewController)
class ShareExtensionNavigationViewController: UINavigationController {
    private let viewModel = ShareExtensionNavigationViewModel(
        environment: .live(
            userNotificationCenter: .current(),
            reduceMotion: { UIAccessibility.isReduceMotionEnabled }))

    override func viewDidLoad() {
        super.viewDidLoad()

        let newStatusViewModel: NewStatusViewModel

        do {
            newStatusViewModel = try viewModel.newStatusViewModel(extensionContext: extensionContext)
        } catch {
            setViewControllers([ShareErrorViewController(error: error)], animated: false)

            return
        }

        setViewControllers(
            [NewStatusViewController(viewModel: newStatusViewModel)],
            animated: false)
    }
}
