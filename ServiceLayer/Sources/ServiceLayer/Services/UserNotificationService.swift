// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import UserNotifications

public struct UserNotificationService {
    let events: AnyPublisher<UserNotificationClient.DelegateEvent, Never>

    private let userNotificationClient: UserNotificationClient

    public init(environment: AppEnvironment) {
        self.userNotificationClient = environment.userNotificationClient
        events = userNotificationClient.delegateEvents
    }
}

public extension UserNotificationService {
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

private extension UserNotificationService {
    func getNotificationSettings() -> AnyPublisher<UNNotificationSettings, Never> {
        Future<UNNotificationSettings, Never> { promise in
            userNotificationClient.getNotificationSettings { promise(.success($0)) }
        }
        .eraseToAnyPublisher()
    }

    func requestProvisionalAuthorization() -> AnyPublisher<Bool, Error> {
        Future<Bool, Error> { promise in
            userNotificationClient.requestAuthorization([.alert, .sound, .badge, .provisional]) { granted, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(granted))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
