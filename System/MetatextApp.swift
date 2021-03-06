// Copyright © 2020 Metabolist. All rights reserved.

import AVKit
import ServiceLayer
import SwiftUI
import ViewModels

@main
struct MetatextApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? ImageCacheConfiguration(environment: Self.environment).configure()
    }

    var body: some Scene {
        WindowGroup {
            // swiftlint:disable:next force_try
            RootView(viewModel: try! RootViewModel(
                        environment: Self.environment,
                        registerForRemoteNotifications: appDelegate.registerForRemoteNotifications))
        }
    }
}

private extension MetatextApp {
    static let environment = AppEnvironment.live(
        userNotificationCenter: .current(),
        reduceMotion: { UIAccessibility.isReduceMotionEnabled },
        autoplayVideos: { UIAccessibility.isVideoAutoplayEnabled })
}
