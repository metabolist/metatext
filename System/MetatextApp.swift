// Copyright © 2020 Metabolist. All rights reserved.

import AVKit
import Kingfisher
import ServiceLayer
import SwiftUI
import ViewModels

@main
struct MetatextApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let environment = AppEnvironment.live(
        userNotificationCenter: .current(),
        reduceMotion: { UIAccessibility.isReduceMotionEnabled })

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? ImageCacheConfiguration(environment: environment).configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                // swiftlint:disable force_try
                viewModel: try! RootViewModel(
                    environment: environment,
                    registerForRemoteNotifications: appDelegate.registerForRemoteNotifications))
                // swiftlint:enable force_try
        }
    }
}

private extension MetatextApp {
    static let imageCacheName = "Images"
    static let imageCacheDirectoryURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: AppEnvironment.appGroup)?
        .appendingPathComponent("Library")
        .appendingPathComponent("Caches")
}
