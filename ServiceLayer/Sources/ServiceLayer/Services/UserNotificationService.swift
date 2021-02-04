// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import UserNotifications

public struct UserNotificationService {
    public let events: AnyPublisher<Event, Never>

    private let userNotificationClient: UserNotificationClient

    public init(environment: AppEnvironment) {
        self.userNotificationClient = environment.userNotificationClient
        events = userNotificationClient.delegateEvents
    }
}

public extension UserNotificationService {
    typealias Event = UserNotificationClient.DelegateEvent
    typealias Content = UNNotificationContent
    typealias MutableContent = UNMutableNotificationContent
    typealias Trigger = UNNotificationTrigger
    typealias Request = UNNotificationRequest

    func isAuthorized(request: Bool) -> AnyPublisher<Bool, Error> {
        getNotificationSettings()
            .map(\.authorizationStatus)
            .flatMap { status -> AnyPublisher<Bool, Error> in
                if request, status == .notDetermined {
                    return requestAuthorization().eraseToAnyPublisher()
                }

                return Just(status == .authorized || status == .provisional)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func add(request: Request) -> AnyPublisher<Never, Error> {
        Future<Void, Error> { promise in
            userNotificationClient.add(request) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        userNotificationClient.removeDeliveredNotifications(identifiers)
    }
}

private extension UserNotificationService {
    func getNotificationSettings() -> AnyPublisher<UNNotificationSettings, Never> {
        Future<UNNotificationSettings, Never> { promise in
            userNotificationClient.getNotificationSettings { promise(.success($0)) }
        }
        .eraseToAnyPublisher()
    }

    func requestAuthorization() -> AnyPublisher<Bool, Error> {
        Future<Bool, Error> { promise in
            userNotificationClient.requestAuthorization([.alert, .sound, .badge]) { granted, error in
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
