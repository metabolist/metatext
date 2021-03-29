// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct PushNotification: Codable {
    public let accessToken: String
    public let body: String
    public let title: String
    public let icon: UnicodeURL
    public let notificationId: Int
    public let notificationType: MastodonNotification.NotificationType
    public let preferredLocale: String
}
