// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

protocol KeychainServiceType {
    static func setGenericPassword(data: Data, forAccount key: String, service: String) throws
    static func deleteGenericPassword(account: String, service: String) throws
    static func getGenericPassword(account: String, service: String) throws -> Data?
    static func generateKeyAndReturnPublicKey(applicationTag: String) throws -> Data
    static func getPrivateKey(applicationTag: String) throws -> Data?
}

struct KeychainService {}

extension KeychainService: KeychainServiceType {
    static func setGenericPassword(data: Data, forAccount account: String, service: String) throws {
        var query = genericPasswordQueryDictionary(account: account, service: service)

        query[kSecValueData as String] = data

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            throw NSError(status: status)
        }
    }

    static func deleteGenericPassword(account: String, service: String) throws {
        let status = SecItemDelete(genericPasswordQueryDictionary(account: account, service: service) as CFDictionary)

        if status != errSecSuccess {
            throw NSError(status: status)
        }
    }

    static func getGenericPassword(account: String, service: String) throws -> Data? {
        var result: AnyObject?
        var query = genericPasswordQueryDictionary(account: account, service: service)

        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = kCFBooleanTrue

        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw NSError(status: status)
        }
    }

    static func generateKeyAndReturnPublicKey(applicationTag: String) throws -> Data {
        var attributes = keyAttributes
        var error: Unmanaged<CFError>?

        attributes[kSecPrivateKeyAttrs as String] = [
            kSecAttrIsPermanent as String: true,
            kSecAttrApplicationTag as String: Data(applicationTag.utf8)]

        guard
            let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error),
            let publicKey = SecKeyCopyPublicKey(key),
            let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data?
            else { throw error?.takeRetainedValue() ?? NSError() }

        return publicKeyData
    }

    static func getPrivateKey(applicationTag: String) throws -> Data? {
        var result: AnyObject?
        let status = SecItemCopyMatching(keyQueryDictionary(applicationTag: applicationTag) as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw NSError(status: status)
        }
    }
}

private extension KeychainService {
    static let keySizeInBits = 256

    static func genericPasswordQueryDictionary(account: String, service: String) -> [String: Any] {
        [kSecAttrService as String: service,
         kSecAttrAccount as String: account,
         kSecClass as String: kSecClassGenericPassword]
    }

    static func keyQueryDictionary(applicationTag: String) -> [String: Any] {
        [kSecClass as String: kSecClassKey,
         kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
         kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
         kSecAttrKeySizeInBits as String: keySizeInBits,
         kSecAttrApplicationTag as String: applicationTag,
         kSecReturnRef as String: true]
    }

    static let keyAttributes: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
        kSecAttrKeySizeInBits as String: keySizeInBits]
}
