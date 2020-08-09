// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

protocol KeychainServiceType {
    func set(data: Data, forKey key: String) throws
    func deleteData(key: String) throws
    func getData(key: String) throws -> Data?
}

struct KeychainService {
    let serviceName: String
}

extension KeychainService: KeychainServiceType {
    func set(data: Data, forKey key: String) throws {
        var query = queryDictionary(key: key)

        query[kSecValueData as String] = data

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            throw NSError(status: status)
        }
    }

    func deleteData(key: String) throws {
        let status = SecItemDelete(queryDictionary(key: key) as CFDictionary)

        if status != errSecSuccess {
            throw NSError(status: status)
        }
    }

    func getData(key: String) throws -> Data? {
        var result: AnyObject?
        var query = queryDictionary(key: key)

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
}

private extension KeychainService {
    private func queryDictionary(key: String) -> [String: Any] {
        [
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecClass as String: kSecClassGenericPassword
        ]
    }
}
