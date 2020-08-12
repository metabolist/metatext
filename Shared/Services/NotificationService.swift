// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import UserNotifications

struct NotificationService {
    private let userNotificationCenter: UNUserNotificationCenter

    init(userNotificationCenter: UNUserNotificationCenter = .current()) {
        self.userNotificationCenter = userNotificationCenter
    }
}

extension NotificationService {
    func isAuthorized() -> AnyPublisher<Bool, Error> {
        getNotificationSettings()
            .map(\.authorizationStatus)
            .flatMap { status -> AnyPublisher<Bool, Error> in
                if status == .notDetermined {
                    return requestProvisionalAuthorization().eraseToAnyPublisher()
                }

                return Just(status == .authorized || status == .provisional)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

private extension NotificationService {
    func getNotificationSettings() -> AnyPublisher<UNNotificationSettings, Never> {
        Future<UNNotificationSettings, Never> { promise in
            userNotificationCenter.getNotificationSettings { promise(.success($0)) }
        }
        .eraseToAnyPublisher()
    }

    func requestProvisionalAuthorization() -> AnyPublisher<Bool, Error> {
        Future<Bool, Error> { promise in
            userNotificationCenter.requestAuthorization(
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
