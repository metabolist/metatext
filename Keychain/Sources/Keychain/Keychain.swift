// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public protocol Keychain {
    static func setGenericPassword(data: Data, forAccount key: String, service: String) throws
    static func deleteGenericPassword(account: String, service: String) throws
    static func getGenericPassword(account: String, service: String) throws -> Data?
    static func generateKeyAndReturnPublicKey(applicationTag: String, attributes: [String: Any]) throws -> Data
    static func getPrivateKey(applicationTag: String, attributes: [String: Any]) throws -> Data?
    static func deleteKey(applicationTag: String) throws
}

public struct LiveKeychain {}

extension LiveKeychain: Keychain {
    public static func setGenericPassword(data: Data, forAccount account: String, service: String) throws {
        var query = genericPasswordQueryDictionary(account: account, service: service)

        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        var status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            status = SecItemUpdate(
                genericPasswordQueryDictionary(account: account, service: service) as CFDictionary,
                [kSecValueData as String: data] as CFDictionary)
        }

        if status != errSecSuccess {
            throw NSError(status: status)
        }
    }

    public static func deleteGenericPassword(account: String, service: String) throws {
        let status = SecItemDelete(genericPasswordQueryDictionary(account: account, service: service) as CFDictionary)

        if status != errSecSuccess {
            throw NSError(status: status)
        }
    }

    public static func getGenericPassword(account: String, service: String) throws -> Data? {
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

    public static func generateKeyAndReturnPublicKey(applicationTag: String, attributes: [String: Any]) throws -> Data {
        try? deleteKey(applicationTag: applicationTag)

        var attributes = attributes
        var error: Unmanaged<CFError>?

        guard let accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleAfterFirstUnlock,
                [],
                &error)
        else { throw error?.takeRetainedValue() ?? NSError() }

        attributes[kSecPrivateKeyAttrs as String] = [
            kSecAttrIsPermanent as String: true,
            kSecAttrApplicationTag as String: Data(applicationTag.utf8),
            kSecAttrAccessControl as String: accessControl]

        guard
            let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error),
            let publicKey = SecKeyCopyPublicKey(key),
            let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data?
            else { throw error?.takeRetainedValue() ?? NSError() }

        return publicKeyData
    }

    public static func getPrivateKey(applicationTag: String, attributes: [String: Any]) throws -> Data? {
        var result: AnyObject?
        var error: Unmanaged<CFError>?
        var query = keyQueryDictionary(applicationTag: applicationTag)

        query.merge(attributes, uniquingKeysWith: { $1 })
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnRef as String] = kCFBooleanTrue

        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            // swiftlint:disable force_cast
            let secKey = result as! SecKey
            // swiftlint:enable force_cast
            guard let data = SecKeyCopyExternalRepresentation(secKey, &error) else {
                throw error?.takeRetainedValue() ?? NSError()
            }

            return data as Data
        case errSecItemNotFound:
            return nil
        default:
            throw NSError(status: status)
        }
    }

    public static func deleteKey(applicationTag: String) throws {
        let status = SecItemDelete(keyQueryDictionary(applicationTag: applicationTag) as CFDictionary)

        if status != errSecSuccess {
            throw NSError(status: status)
        }
    }
}

private extension LiveKeychain {
    static func genericPasswordQueryDictionary(account: String, service: String) -> [String: Any] {
        [kSecAttrService as String: service,
         kSecAttrAccount as String: account,
         kSecClass as String: kSecClassGenericPassword]
    }

    static func keyQueryDictionary(applicationTag: String) -> [String: Any] {
        [kSecClass as String: kSecClassKey,
         kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
         kSecAttrApplicationTag as String: applicationTag,
         kSecReturnRef as String: true]
    }
}
