// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ServiceLayer

@main
struct MetatextApp: App {
    // swiftlint:disable weak_delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    // swiftlint:enable weak_delegate

    var body: some Scene {
        WindowGroup {
            RootView(
                viewModel: RootViewModel(appDelegate: appDelegate,
                                         // swiftlint:disable force_try
                                         allIdentitiesService: try! AllIdentitiesService(environment: .live),
                                         // swiftlint:enable force_try
                                         userNotificationService: UserNotificationService()))
        }
    }
}
