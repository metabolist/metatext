// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import UserNotifications

class UserNotificationService: NSObject {
    private let userNotificationCenter: UNUserNotificationCenter

    init(userNotificationCenter: UNUserNotificationCenter = .current()) {
        self.userNotificationCenter = userNotificationCenter

        super.init()

        userNotificationCenter.delegate = self
    }
}

extension UserNotificationService {
    func isAuthorized() -> AnyPublisher<Bool, Error> {
        getNotificationSettings()
            .map(\.authorizationStatus)
            .flatMap { [weak self] status -> AnyPublisher<Bool, Error> in
                if status == .notDetermined {
                    return self?.requestProvisionalAuthorization()
                        .eraseToAnyPublisher()
                        ?? Empty().eraseToAnyPublisher()
                }

                return Just(status == .authorized || status == .provisional)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

private extension UserNotificationService {
    func getNotificationSettings() -> AnyPublisher<UNNotificationSettings, Never> {
        Future<UNNotificationSettings, Never> { [weak self] promise in
            self?.userNotificationCenter.getNotificationSettings { promise(.success($0)) }
        }
        .eraseToAnyPublisher()
    }

    func requestProvisionalAuthorization() -> AnyPublisher<Bool, Error> {
        Future<Bool, Error> { [weak self] promise in
            self?.userNotificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge, .provisional]) { granted, error in
                if let error = error {
                    return promise(.failure(error))
                }

                return promise(.success(granted))
            }
        }
        .eraseToAnyPublisher()
    }
}

extension UserNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print(notification.request.content.body)
        completionHandler(.banner)
    }
}
