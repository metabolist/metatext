// Copyright © 2020 Metabolist. All rights reserved.

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
    public let identityID: UUID
    private let keychain: Keychain.Type

    public init(identityID: UUID, keychain: Keychain.Type) {
        self.identityID = identityID
        self.keychain = keychain
    }
}

public extension Secrets {
    enum Item: String, CaseIterable {
        case clientID
        case clientSecret
        case accessToken
        case pushKey
        case pushAuth
    }
}

enum SecretsServiceError: Error {
    case itemAbsent
}

extension Secrets.Item {
    enum Kind {
        case genericPassword
        case key
    }

    var kind: Kind {
        switch self {
        case .pushKey: return .key
        default: return .genericPassword
        }
    }
}

public extension Secrets {
    func set(_ data: SecretsStorable, forItem item: Item) throws {
        try keychain.setGenericPassword(
            data: data.dataStoredInSecrets,
            forAccount: key(item: item),
            service: Self.keychainServiceName)
    }

    func item<T: SecretsStorable>(_ item: Item) throws -> T {
        guard let data = try keychain.getGenericPassword(
                account: key(item: item),
                service: Self.keychainServiceName) else {
            throw SecretsServiceError.itemAbsent
        }

        return try T.fromDataStoredInSecrets(data)
    }

    func deleteAllItems() throws {
        for item in Secrets.Item.allCases {
            switch item.kind {
            case .genericPassword:
                try keychain.deleteGenericPassword(
                    account: key(item: item),
                    service: Self.keychainServiceName)
            case .key:
                try keychain.deleteKey(applicationTag: key(item: item))
            }
        }
    }

    func generatePushKeyAndReturnPublicKey() throws -> Data {
        try keychain.generateKeyAndReturnPublicKey(
            applicationTag: key(item: .pushKey),
            attributes: PushKey.attributes)
    }

    func getPushKey() throws -> Data? {
        try keychain.getPrivateKey(
            applicationTag: key(item: .pushKey),
            attributes: PushKey.attributes)
    }

    func generatePushAuth() throws -> Data {
        var bytes = [UInt8](repeating: 0, count: PushKey.authLength)

        _ = SecRandomCopyBytes(kSecRandomDefault, PushKey.authLength, &bytes)

        let pushAuth = Data(bytes)

        try set(pushAuth, forItem: .pushAuth)

        return pushAuth
    }

    func getPushAuth() throws -> Data? {
        try item(.pushAuth)
    }
}

private extension Secrets {
    static let keychainServiceName = "com.metabolist.metatext"

    func key(item: Item) -> String {
        identityID.uuidString + "." + item.rawValue
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

private struct PushKey {
    static let authLength = 16
    static let sizeInBits = 256
    static let attributes: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
        kSecAttrKeySizeInBits as String: sizeInBits]
}
