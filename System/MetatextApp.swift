// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

@main
struct MetatextApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView(
                // swiftlint:disable force_try
                viewModel: try! RootViewModel(
                    environment: .live(
                        userNotificationCenter: .current(),
                        reduceMotion: { UIAccessibility.isReduceMotionEnabled }),
                    registerForRemoteNotifications: appDelegate.registerForRemoteNotifications))
                // swiftlint:enable force_try
        }
    }
}
