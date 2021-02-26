// Copyright © 2020 Metabolist. All rights reserved.

import Base16
import CryptoKit
import Foundation
import Keychain

public protocol SecretsStorable {
    var dataStoredInSecrets: Data { get }
    static func fromDataStoredInSecrets(_ data: Data) throws -> Self
}

enum SecretsStorableError: Error {
    case conversionFromDataStoredInSecrets(Data)
}

public struct Secrets {
    public let identityId: UUID
    private let keychain: Keychain.Type

    public init(identityId: UUID, keychain: Keychain.Type) {
        self.identityId = identityId
        self.keychain = keychain
    }
}

public extension Secrets {
    enum Item: String, CaseIterable {
        case instanceURL
        case clientId
        case clientSecret
        case accessToken
        case pushKey
        case pushAuth
        case databaseKey
        case imageCacheKey
        case identityDatabaseName
        case accountId
        case username
    }
}

public enum SecretsError: Error {
    case itemAbsent
}

extension Secrets.Item {
    enum Kind {
        case genericPassword
        case key
    }

    // Note `databaseKey` and `imageCacheKey` are stored as generic passwords, not keys
    var kind: Kind {
        switch self {
        case .pushKey: return .key
        default: return .genericPassword
        }
    }
}

public extension Secrets {
    static func identityDatabaseName(keychain: Keychain.Type) throws -> String {
        do {
            return try unscopedItem(.identityDatabaseName, keychain: keychain)
        } catch SecretsError.itemAbsent {
            let identityDatabaseName = UUID().uuidString

            try setUnscoped(identityDatabaseName, forItem: .identityDatabaseName, keychain: keychain)

            return identityDatabaseName
        }
    }

    static func imageCacheKey(keychain: Keychain.Type) throws -> Data {
        do {
            return try unscopedItem(.imageCacheKey, keychain: keychain)
        } catch SecretsError.itemAbsent {
            let imageCacheKey = Data(SymmetricKey(size: .bits256).withUnsafeBytes(Array.init))

            try setUnscoped(imageCacheKey, forItem: .imageCacheKey, keychain: keychain)

            return imageCacheKey
        }
    }

    // https://www.zetetic.net/sqlcipher/sqlcipher-api/#key
    static func databaseKey(identityId: UUID?, keychain: Keychain.Type) throws -> String {
        let passphraseData: Data
        let scopedSecrets: Secrets?

        if let identityId = identityId {
            scopedSecrets = Secrets(identityId: identityId, keychain: keychain)
        } else {
            scopedSecrets = nil
        }

        do {
            passphraseData = try scopedSecrets?.item(.databaseKey)
                ?? unscopedItem(.databaseKey, keychain: keychain)
        } catch SecretsError.itemAbsent {
            var bytes = [UInt8](repeating: 0, count: databaseKeyLength)
            let status = SecRandomCopyBytes(kSecRandomDefault, databaseKeyLength, &bytes)

            if status == errSecSuccess {
                passphraseData = Data(bytes)

                if let scopedSecrets = scopedSecrets {
                    try scopedSecrets.set(passphraseData, forItem: .databaseKey)
                } else {
                    try setUnscoped(passphraseData, forItem: .databaseKey, keychain: keychain)
                }
            } else {
                throw NSError(status: status)
            }
        }

        return "x'\(passphraseData.base16EncodedString(options: [.uppercase]))'"
    }

    func deleteAllItems() {
        for item in Secrets.Item.allCases {
            do {
                switch item.kind {
                case .genericPassword:
                    try keychain.deleteGenericPassword(
                        account: scopedKey(item: item),
                        service: Self.keychainServiceName)
                case .key:
                    try keychain.deleteKey(applicationTag: scopedKey(item: item))
                }
            } catch {
                // no-op
            }
        }
    }

    func getInstanceURL() throws -> URL {
        try item(.instanceURL)
    }

    func setInstanceURL(_ instanceURL: URL) throws {
        try set(instanceURL, forItem: .instanceURL)
    }

    func getClientId() throws -> String {
        try item(.clientId)
    }

    func setClientId(_ clientId: String) throws {
        try set(clientId, forItem: .clientId)
    }

    func getClientSecret() throws -> String {
        try item(.clientSecret)
    }

    func setClientSecret(_ clientSecret: String) throws {
        try set(clientSecret, forItem: .clientSecret)
    }

    func getAccessToken() throws -> String {
        try item(.accessToken)
    }

    func setAccessToken(_ accessToken: String) throws {
        try set(accessToken, forItem: .accessToken)
    }

    func getAccountId() throws -> String {
        try item(.accountId)
    }

    func setAccountId(_ accountId: String) throws {
        try set(accountId, forItem: .accountId)
    }

    func getUsername() throws -> String {
        try item(.username)
    }

    func setUsername(_ username: String) throws {
        try set(username, forItem: .username)
    }

    func generatePushKeyAndReturnPublicKey() throws -> Data {
        try keychain.generateKeyAndReturnPublicKey(
            applicationTag: scopedKey(item: .pushKey),
            attributes: PushKey.attributes)
    }

    func getPushKey() throws -> Data? {
        try keychain.getPrivateKey(
            applicationTag: scopedKey(item: .pushKey),
            attributes: PushKey.attributes)
    }

    func generatePushAuth() throws -> Data {
        var bytes = [UInt8](repeating: 0, count: PushKey.authLength)
        let status = SecRandomCopyBytes(kSecRandomDefault, PushKey.authLength, &bytes)

        if status == errSecSuccess {
            let pushAuth = Data(bytes)

            try set(pushAuth, forItem: .pushAuth)

            return pushAuth
        } else {
            throw NSError(status: status)
        }
    }

    func getPushAuth() throws -> Data? {
        try item(.pushAuth)
    }
}

private extension Secrets {
    static let keychainServiceName = "com.metabolist.metatext"
    static let databaseKeyLength = 48

    private static func set(_ data: SecretsStorable, forAccount account: String, keychain: Keychain.Type) throws {
        try keychain.setGenericPassword(
            data: data.dataStoredInSecrets,
            forAccount: account,
            service: keychainServiceName)
    }

    private static func get<T: SecretsStorable>(account: String, keychain: Keychain.Type) throws -> T {
        guard let data = try keychain.getGenericPassword(
                account: account,
                service: keychainServiceName) else {
            throw SecretsError.itemAbsent
        }

        return try T.fromDataStoredInSecrets(data)
    }

    static func setUnscoped(_ data: SecretsStorable, forItem item: Item, keychain: Keychain.Type) throws {
        try set(data, forAccount: item.rawValue, keychain: keychain)
    }

    static func unscopedItem<T: SecretsStorable>(_ item: Item, keychain: Keychain.Type) throws -> T {
        try get(account: item.rawValue, keychain: keychain)
    }

    func scopedKey(item: Item) -> String {
        identityId.uuidString.appending(".").appending(item.rawValue)
    }

    func set(_ data: SecretsStorable, forItem item: Item) throws {
        try Self.set(data, forAccount: scopedKey(item: item), keychain: keychain)
    }

    func item<T: SecretsStorable>(_ item: Item) throws -> T {
        try Self.get(account: scopedKey(item: item), keychain: keychain)
    }
}

extension Data: SecretsStorable {
    public var dataStoredInSecrets: Data { self }

    public static func fromDataStoredInSecrets(_ data: Data) throws -> Data {
        data
    }
}

extension String: SecretsStorable {
    public var dataStoredInSecrets: Data { Data(utf8) }

    public static func fromDataStoredInSecrets(_ data: Data) throws -> String {
        guard let string = String(data: data, encoding: .utf8) else {
            throw SecretsStorableError.conversionFromDataStoredInSecrets(data)
        }

        return string
    }
}

extension URL: SecretsStorable {
    public var dataStoredInSecrets: Data { absoluteString.dataStoredInSecrets }

    public static func fromDataStoredInSecrets(_ data: Data) throws -> URL {
        guard let url = URL(string: try String.fromDataStoredInSecrets(data)) else {
            throw SecretsStorableError.conversionFromDataStoredInSecrets(data)
        }

        return url
    }
}

private struct PushKey {
    static let authLength = 16
    static let sizeInBits = 256
    static let attributes: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
        kSecAttrKeySizeInBits as String: sizeInBits]
}
