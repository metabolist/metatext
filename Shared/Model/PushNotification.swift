// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct PushNotification: Codable {
    enum NotificationType: String, Codable, Unknowable {
        case mention
        case reblog
        case favourite
        case follow
        case unknown

        static var unknownCase: Self { .unknown }
    }

    let accessToken: String
    let body: String
    let title: String
    let icon: URL
    let notificationId: Int
    let notificationType: NotificationType
    let preferredLocale: String
}
