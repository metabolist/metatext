// Copyright © 2020 Metabolist. All rights reserved.

import AVKit
import Combine
import GRDB
import ServiceLayer
import SwiftUI
import ViewModels

@main
struct MetatextApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private var cancellables = Set<AnyCancellable>()

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? ImageCacheConfiguration(environment: Self.environment).configure()

        // swiftlint:disable:next line_length
        // https://github.com/groue/GRDB.swift/blob/master/Documentation/SharingADatabase.md#how-to-limit-the-0xdead10cc-exception
        // This would ideally be accomplished with `@Environment(\.scenePhase) private var scenePhase`
        // and `.onChange(of: scenePhase)` on the `WindowGroup`, but that does not give an accurate
        // aggregate scene activation state for iPad multitasking as of iOS 14.4.1
        Publishers.MergeMany([UIScene.willConnectNotification,
                              UIScene.didDisconnectNotification,
                              UIScene.didActivateNotification,
                              UIScene.willDeactivateNotification,
                              UIScene.willEnterForegroundNotification,
                              UIScene.didEnterBackgroundNotification]
                                .map { NotificationCenter.default.publisher(for: $0) })
            .map { _ in
                UIApplication.shared.openSessions
                    .compactMap(\.scene)
                    .allSatisfy { $0.activationState == .background }
            }
            .removeDuplicates()
            .sink {
                NotificationCenter.default.post(
                    name: $0 ? Database.suspendNotification : Database.resumeNotification,
                    object: nil)
            }
            .store(in: &cancellables)
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
