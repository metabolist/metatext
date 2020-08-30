// Copyright © 2020 Metabolist. All rights reserved.

import UserNotifications
import CryptoKit
import Mastodon

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else { return }

        let pushNotification: PushNotification

        do {
            let decryptedJSON = try Self.extractAndDecrypt(userInfo: request.content.userInfo)

            pushNotification = try APIDecoder().decode(PushNotification.self, from: decryptedJSON)
        } catch {
            contentHandler(bestAttemptContent)

            return
        }

        bestAttemptContent.title = pushNotification.title
        bestAttemptContent.body = pushNotification.body

        let fileName = pushNotification.icon.lastPathComponent
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(fileName)

        do {
            let iconData = try Data(contentsOf: pushNotification.icon)

            try iconData.write(to: fileURL)
            bestAttemptContent.attachments = [try UNNotificationAttachment(identifier: fileName, url: fileURL)]
        } catch {
            // no-op
        }

        contentHandler(bestAttemptContent)
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}

enum NotificationServiceError: Error {
    case userInfoDataAbsent
    case keychainDataAbsent
}

private extension NotificationService {
    static let identityIDUserInfoKey = "i"
    static let encryptedMessageUserInfoKey = "m"
    static let saltUserInfoKey = "s"
    static let serverPublicKeyUserInfoKey = "k"
    static let keyLength = 16
    static let nonceLength = 12
    static let pseudoRandomKeyLength = 32
    static let paddedByteCount = 2
    static let curve = "P-256"

    enum HKDFInfo: String {
        case auth, aesgcm, nonce

        var bytes: [UInt8] {
            Array("Content-Encoding: \(self)\0".utf8)
        }
    }

    static func extractAndDecrypt(userInfo: [AnyHashable: Any]) throws -> Data {
        guard
            let identityIDString = userInfo[identityIDUserInfoKey] as? String,
            let identityID = UUID(uuidString: identityIDString),
            let encryptedMessageBase64 = (userInfo[encryptedMessageUserInfoKey] as? String)?.URLSafeBase64ToBase64(),
            let encryptedMessage = Data(base64Encoded: encryptedMessageBase64),
            let saltBase64 = (userInfo[saltUserInfoKey] as? String)?.URLSafeBase64ToBase64(),
            let salt = Data(base64Encoded: saltBase64),
            let serverPublicKeyBase64 = (userInfo[serverPublicKeyUserInfoKey] as? String)?.URLSafeBase64ToBase64(),
            let serverPublicKeyData = Data(base64Encoded: serverPublicKeyBase64)
        else { throw NotificationServiceError.userInfoDataAbsent }

        let secretsService = SecretsService(identityID: identityID, keychainService: LiveKeychainService.self)

        guard
            let auth = try secretsService.getPushAuth(),
            let pushKey = try secretsService.getPushKey()
        else { throw NotificationServiceError.keychainDataAbsent }

        return try decrypt(encryptedMessage: encryptedMessage,
                           privateKeyData: pushKey,
                           serverPublicKeyData: serverPublicKeyData,
                           auth: auth,
                           salt: salt)
    }

    static func decrypt(encryptedMessage: Data,
                        privateKeyData: Data,
                        serverPublicKeyData: Data,
                        auth: Data,
                        salt: Data) throws -> Data {
        let privateKey = try P256.KeyAgreement.PrivateKey(x963Representation: privateKeyData)
        let serverPublicKey = try P256.KeyAgreement.PublicKey(x963Representation: serverPublicKeyData)
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: serverPublicKey)

        var keyInfo = HKDFInfo.aesgcm.bytes
        var nonceInfo = HKDFInfo.nonce.bytes
        var context = Array(curve.utf8)
        let publicKeyData = privateKey.publicKey.x963Representation

        context.append(0)
        context.append(0)
        context.append(UInt8(publicKeyData.count))
        context += Array(publicKeyData)
        context.append(0)
        context.append(UInt8(serverPublicKeyData.count))
        context += Array(serverPublicKeyData)

        keyInfo += context
        nonceInfo += context

        let pseudoRandomKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: auth,
            sharedInfo: HKDFInfo.auth.bytes,
            outputByteCount: pseudoRandomKeyLength)
        let key = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: pseudoRandomKey,
            salt: salt,
            info: keyInfo,
            outputByteCount: keyLength)
        let nonce = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: pseudoRandomKey,
            salt: salt,
            info: nonceInfo,
            outputByteCount: nonceLength)

        let sealedBox = try AES.GCM.SealedBox(combined: nonce.withUnsafeBytes(Array.init) + encryptedMessage)
        let decrypted = try AES.GCM.open(sealedBox, using: key)
        let unpadded = decrypted.suffix(from: paddedByteCount)

        return Data(unpadded)
    }
}

extension String {
    func URLSafeBase64ToBase64() -> String {
        var base64 = replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let countMod4 = count % 4

        if countMod4 != 0 {
            base64.append(String(repeating: "=", count: 4 - countMod4))
        }

        return base64
    }
}
