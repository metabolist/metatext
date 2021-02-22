// Copyright © 2020 Metabolist. All rights reserved.

import AVKit
import ServiceLayer
import SwiftUI
import ViewModels

@main
struct MetatextApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    // swiftlint:disable:next force_try
    private let viewModel = try! RootViewModel(environment: Self.environment)

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? ImageCacheConfiguration(environment: Self.environment).configure()
    }

    var body: some Scene {
        viewModel.registerForRemoteNotifications = appDelegate.registerForRemoteNotifications

        return WindowGroup {
            RootView(viewModel: viewModel)
        }
    }
}

private extension MetatextApp {
    static let environment = AppEnvironment.live(
        userNotificationCenter: .current(),
        reduceMotion: { UIAccessibility.isReduceMotionEnabled })
}
