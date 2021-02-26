// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import CryptoKit
import Foundation
import Mastodon
import MastodonAPI
import Secrets

enum NotificationExtensionServiceError: Error {
    case userInfoDataAbsent
    case keychainDataAbsent
}

public struct PushNotificationParsingService {
    private let environment: AppEnvironment

    public init(environment: AppEnvironment) {
        self.environment = environment
    }
}

public extension PushNotificationParsingService {
    static let identityIdUserInfoKey = "i"
    static let pushNotificationUserInfoKey = "com.metabolist.metatext.push-notification-user-info-key"

    func extractAndDecrypt(userInfo: [AnyHashable: Any]) throws -> (Data, Identity.Id) {
        guard let identityIdString = userInfo[Self.identityIdUserInfoKey] as? String,
              let identityId = Identity.Id(uuidString: identityIdString),
              let encryptedMessageBase64 = (userInfo[Self.encryptedMessageUserInfoKey] as? String)?
                .URLSafeBase64ToBase64(),
              let encryptedMessage = Data(base64Encoded: encryptedMessageBase64),
              let saltBase64 = (userInfo[Self.saltUserInfoKey] as? String)?.URLSafeBase64ToBase64(),
              let salt = Data(base64Encoded: saltBase64),
              let serverPublicKeyBase64 = (userInfo[Self.serverPublicKeyUserInfoKey] as? String)?
                .URLSafeBase64ToBase64(),
              let serverPublicKeyData = Data(base64Encoded: serverPublicKeyBase64)
        else { throw NotificationExtensionServiceError.userInfoDataAbsent }

        let secrets = Secrets(identityId: identityId, keychain: environment.keychain)

        guard let auth = try secrets.getPushAuth(),
              let pushKey = try secrets.getPushKey()
        else { throw NotificationExtensionServiceError.keychainDataAbsent }

        return (try Self.decrypt(encryptedMessage: encryptedMessage,
                                 privateKeyData: pushKey,
                                 serverPublicKeyData: serverPublicKeyData,
                                 auth: auth,
                                 salt: salt),
                identityId)
    }

    func handle(identityId: Identity.Id) -> Result<String, Error> {
        let secrets = Secrets(identityId: identityId, keychain: environment.keychain)

        return Result { try secrets.getUsername().appending("@").appending(secrets.getInstanceURL().host ?? "") }
    }

    func title(pushNotification: PushNotification, identityId: Identity.Id) -> AnyPublisher<String, Error> {
        switch pushNotification.notificationType {
        case .poll, .status:
            let secrets = Secrets(identityId: identityId, keychain: environment.keychain)
            let instanceURL: URL

            do {
                instanceURL = try secrets.getInstanceURL()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }

            let mastodonAPIClient = MastodonAPIClient(session: .shared, instanceURL: instanceURL)

            mastodonAPIClient.accessToken = pushNotification.accessToken

            let endpoint = NotificationEndpoint.notification(id: String(pushNotification.notificationId))

            return mastodonAPIClient.request(endpoint)
                .map {
                    switch pushNotification.notificationType {
                    case .status:
                        return String.localizedStringWithFormat(
                            NSLocalizedString("notification.status-%@", comment: ""),
                            $0.account.displayName)
                    case .poll:
                        guard let accountId = try? secrets.getAccountId() else {
                            return NSLocalizedString("notification.poll.unknown", comment: "")
                        }

                        if $0.account.id == accountId {
                            return NSLocalizedString("notification.poll.own", comment: "")
                        } else {
                            return NSLocalizedString("notification.poll", comment: "")
                        }
                    default:
                        return pushNotification.title
                    }
                }
                .eraseToAnyPublisher()
        default:
            return Just(pushNotification.title).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
    }
}

private extension PushNotificationParsingService {
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

private extension String {
    func URLSafeBase64ToBase64() -> String {
        var base64 = replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let countMod4 = count % 4

        if countMod4 != 0 {
            base64.append(String(repeating: "=", count: 4 - countMod4))
        }

        return base64
    }
}
