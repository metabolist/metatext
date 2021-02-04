// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import Mastodon
import ServiceLayer
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
    private let environment = AppEnvironment.live(
        userNotificationCenter: .current(),
        reduceMotion: { false })

    override init() {
        super.init()
    }

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else { return }

        let parsingService = PushNotificationParsingService(environment: environment)
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

        let appPreferences = AppPreferences(environment: environment)

        if appPreferences.notificationSounds.contains(pushNotification.notificationType) {
            bestAttemptContent.sound = .default
        }

        if appPreferences.notificationAccountName,
           let accountName = try? AllIdentitiesService(environment: environment).identity(id: identityId)?.handle {
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
    static func addImage(url: URL,
                         bestAttemptContent: UNMutableNotificationContent,
                         contentHandler: @escaping (UNNotificationContent) -> Void) {
        let fileName = url.lastPathComponent
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(fileName)

        KingfisherManager.shared.retrieveImage(with: url) {
            switch $0 {
            case let .success(result):
                let format: ImageFormat

                switch fileURL.pathExtension.lowercased() {
                case "jpg", "jpeg":
                    format = .JPEG
                case "gif":
                    format = .GIF
                case "png":
                    format = .PNG
                default:
                    format = .unknown
                }

                do {
                    try result.image.kf.data(format: format)?.write(to: fileURL)
                    bestAttemptContent.attachments =
                        [try UNNotificationAttachment(identifier: fileName, url: fileURL)]
                    contentHandler(bestAttemptContent)
                } catch {
                    contentHandler(bestAttemptContent)
                }
            case .failure:
                contentHandler(bestAttemptContent)
            }
        }
    }
}
