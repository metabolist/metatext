// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import SDWebImage
import ServiceLayer
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
    override init() {
        super.init()

        try? ImageCacheConfiguration(environment: Self.environment).configure()
    }

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else { return }

        let parsingService = PushNotificationParsingService(environment: Self.environment)
        let decryptedJSON: Data
        let identityId: Identity.Id
        let pushNotification: PushNotification

        do {
            (decryptedJSON, identityId) = try parsingService.extractAndDecrypt(userInfo: request.content.userInfo)
            pushNotification = try MastodonDecoder().decode(PushNotification.self, from: decryptedJSON)
        } catch {
            contentHandler(bestAttemptContent)

            return
        }

        bestAttemptContent.userInfo[PushNotificationParsingService.pushNotificationUserInfoKey] = decryptedJSON
        bestAttemptContent.title = pushNotification.title
        bestAttemptContent.body = XMLUnescaper(string: pushNotification.body).unescape()

        let appPreferences = AppPreferences(environment: Self.environment)

        if appPreferences.notificationSounds.contains(pushNotification.notificationType) {
            bestAttemptContent.sound = .default
        }

        if appPreferences.notificationAccountName,
           let accountName = try? AllIdentitiesService(environment: Self.environment).identity(id: identityId)?.handle {
            bestAttemptContent.subtitle = accountName
        }

        if appPreferences.notificationPictures {
            Self.addImage(url: pushNotification.icon,
                          bestAttemptContent: bestAttemptContent,
                          contentHandler: contentHandler)
        } else {
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}

private extension NotificationService {
    private static let environment = AppEnvironment.live(
        userNotificationCenter: .current(),
        reduceMotion: { false })

    static func addImage(url: URL,
                         bestAttemptContent: UNMutableNotificationContent,
                         contentHandler: @escaping (UNNotificationContent) -> Void) {
        let fileName = url.lastPathComponent
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(fileName)

        SDWebImageManager.shared.loadImage(with: url, options: [], progress: nil) { _, data, _, _, _, _ in
            if let data = data {
                do {
                    try data.write(to: fileURL)
                    bestAttemptContent.attachments =
                        [try UNNotificationAttachment(identifier: fileName, url: fileURL)]
                    contentHandler(bestAttemptContent)
                } catch {
                    contentHandler(bestAttemptContent)
                }
            } else {
                contentHandler(bestAttemptContent)
            }
        }
    }
}
