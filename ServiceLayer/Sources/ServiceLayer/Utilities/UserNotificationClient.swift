// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import UserNotifications

public struct UserNotificationClient {
    public enum DelegateEvent {
        case willPresentNotification(UNNotification, completionHandler: (UNNotificationPresentationOptions) -> Void)
        case didReceiveResponse(UNNotificationResponse, completionHandler: () -> Void)
        case openSettingsForNotification(UNNotification?)
    }

    public var getNotificationSettings: (@escaping (UNNotificationSettings) -> Void) -> Void
    public var requestAuthorization: (UNAuthorizationOptions, @escaping (Bool, Error?) -> Void) -> Void
    public var delegateEvents: AnyPublisher<DelegateEvent, Never>

    public init(
        getNotificationSettings: @escaping (@escaping (UNNotificationSettings) -> Void) -> Void,
        requestAuthorization: @escaping (UNAuthorizationOptions, @escaping (Bool, Error?) -> Void) -> Void,
        delegateEvents: AnyPublisher<DelegateEvent, Never>) {
        self.getNotificationSettings = getNotificationSettings
        self.requestAuthorization = requestAuthorization
        self.delegateEvents = delegateEvents
    }
}

extension UserNotificationClient {
    public static func live(_ userNotificationCenter: UNUserNotificationCenter) -> Self {
        // swiftlint:disable nesting
        final class Delegate: NSObject, UNUserNotificationCenterDelegate {
            let subject: PassthroughSubject<DelegateEvent, Never>

            init(subject: PassthroughSubject<DelegateEvent, Never>) {
                self.subject = subject
            }

            func userNotificationCenter(
                _ center: UNUserNotificationCenter,
                willPresent notification: UNNotification,
                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
                subject.send(.willPresentNotification(notification, completionHandler: completionHandler))
            }

            func userNotificationCenter(_ center: UNUserNotificationCenter,
                                        didReceive response: UNNotificationResponse,
                                        withCompletionHandler completionHandler: @escaping () -> Void) {
                subject.send(.didReceiveResponse(response, completionHandler: completionHandler))
            }

            func userNotificationCenter(_ center: UNUserNotificationCenter,
                                        openSettingsFor notification: UNNotification?) {
                subject.send(.openSettingsForNotification(notification))
            }
        }
        // swiftlint:enable nesting

        let subject = PassthroughSubject<DelegateEvent, Never>()
        var delegate: Delegate? = Delegate(subject: subject)
        userNotificationCenter.delegate = delegate

        return UserNotificationClient(
            getNotificationSettings: userNotificationCenter.getNotificationSettings,
            requestAuthorization: userNotificationCenter.requestAuthorization,
            delegateEvents: subject
                .handleEvents(receiveCancel: { delegate = nil })
                .eraseToAnyPublisher())
    }
}
