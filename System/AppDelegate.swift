// Copyright © 2020 Metabolist. All rights reserved.

#if os(macOS)
import AppKit
typealias AppDelegateType = NSApplicationDelegate
typealias ApplicationType = NSApplication
#else
import UIKit
typealias AppDelegateType = UIApplicationDelegate
typealias ApplicationType = UIApplication
#endif

import Combine

class AppDelegate: NSObject {
    @Published private var application: ApplicationType?
    private let remoteNotificationDeviceTokens = PassthroughSubject<Data, Error>()
}

extension AppDelegate {
    func registerForRemoteNotifications() -> AnyPublisher<String, Error> {
        $application
            .compactMap { $0 }
            .handleEvents(receiveOutput: { $0.registerForRemoteNotifications() })
            .setFailureType(to: Error.self)
            .zip(remoteNotificationDeviceTokens)
            .first()
            .map { $1.hexEncodedString() }
            .eraseToAnyPublisher()
    }
}

extension AppDelegate: AppDelegateType {
    #if os(macOS)
    func applicationDidFinishLaunching(_ notification: Notification) {
        application = notification.object as? ApplicationType
    }
    #else
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        self.application = application

        return true
    }
    #endif

    func application(_ application: ApplicationType,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // this doesn't get called on macOS, need to figure out why
        remoteNotificationDeviceTokens.send(deviceToken)
    }

    func application(_ application: ApplicationType,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        remoteNotificationDeviceTokens.send(completion: .failure(error))
    }
}
