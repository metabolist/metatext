// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import UIKit

final class AppDelegate: NSObject {
    @Published private var application: UIApplication?
    private let deviceTokenSubject = PassthroughSubject<Data, Error>()
}

extension AppDelegate {
    func registerForRemoteNotifications() -> AnyPublisher<Data, Error> {
        $application
            .compactMap { $0 }
            .handleEvents(receiveOutput: { $0.registerForRemoteNotifications() })
            .setFailureType(to: Error.self)
            .zip(deviceTokenSubject)
            .first()
            .map { $1 }
            .eraseToAnyPublisher()
    }
}

extension AppDelegate: UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        self.application = application

        configureGlobalAppearance()

        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        deviceTokenSubject.send(deviceToken)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        deviceTokenSubject.send(completion: .failure(error))
    }
}

private extension AppDelegate {
    func configureGlobalAppearance() {
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()

            appearance.configureWithDefaultBackground()

            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
