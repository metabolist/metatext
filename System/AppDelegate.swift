// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import UIKit

class AppDelegate: NSObject {
    @Published private var application: UIApplication?
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

extension AppDelegate: UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        self.application = application

        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        remoteNotificationDeviceTokens.send(deviceToken)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        remoteNotificationDeviceTokens.send(completion: .failure(error))
    }
}
