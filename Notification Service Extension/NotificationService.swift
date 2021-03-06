// Copyright © 2020 Metabolist. All rights reserved.

import Combine
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
    var cancellables = Set<AnyCancellable>()

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
           case let .success(handle) = parsingService.handle(identityId: identityId) {
            bestAttemptContent.subtitle = handle
        }

        Self.attachment(imageURL: pushNotification.icon)
            .map { [$0] }
            .replaceError(with: [])
            .handleEvents(receiveOutput: { bestAttemptContent.attachments = $0 })
            .zip(parsingService.title(pushNotification: pushNotification, identityId: identityId)
                    .replaceError(with: pushNotification.title)
                    .handleEvents(receiveOutput: { bestAttemptContent.title = $0 }))
            .sink { _ in contentHandler(bestAttemptContent) }
            .store(in: &cancellables)
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
        reduceMotion: { false },
        autoplayVideos: { true })

    enum ImageError: Error {
        case dataMissing
    }

    static func attachment(imageURL: URL) -> AnyPublisher<UNNotificationAttachment, Error> {
        let fileName = imageURL.lastPathComponent
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(fileName)

        return Future<UNNotificationAttachment, Error> { promise in
            SDWebImageManager.shared.loadImage(with: imageURL, options: [], progress: nil) { _, data, error, _, _, _ in
                if let error = error {
                    promise(.failure(error))
                } else if let data = data {
                    let result = Result<UNNotificationAttachment, Error> {
                        try data.write(to: fileURL)

                        return try UNNotificationAttachment(identifier: fileName, url: fileURL)
                    }

                    promise(result)
                } else {
                    promise(.failure(ImageError.dataMissing))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
