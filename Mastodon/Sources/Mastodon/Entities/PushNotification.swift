// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct PushNotification: Codable {
    public enum NotificationType: String, Codable, Unknowable {
        case mention
        case reblog
        case favourite
        case follow
        case unknown

        public static var unknownCase: Self { .unknown }
    }

    public let accessToken: String
    public let body: String
    public let title: String
    public let icon: URL
    public let notificationId: Int
    public let notificationType: NotificationType
    public let preferredLocale: String
}
