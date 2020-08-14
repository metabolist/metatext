// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

protocol SecretsStorable {
    var dataStoredInSecrets: Data { get }
    static func fromDataStoredInSecrets(_ data: Data) throws -> Self
}

enum SecretsStorableError: Error {
    case conversionFromDataStoredInSecrets(Data)
}

struct SecretsService {
    let identityID: UUID
    private let keychainService: KeychainService.Type

    init(identityID: UUID, keychainService: KeychainService.Type) {
        self.identityID = identityID
        self.keychainService = keychainService
    }
}

extension SecretsService {
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

extension SecretsService.Item {
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

extension SecretsService {
    func set(_ data: SecretsStorable, forItem item: Item) throws {
        try keychainService.setGenericPassword(
            data: data.dataStoredInSecrets,
            forAccount: key(item: item),
            service: Self.keychainServiceName)
    }

    func item<T: SecretsStorable>(_ item: Item) throws -> T {
        guard let data = try keychainService.getGenericPassword(
                account: key(item: item),
                service: Self.keychainServiceName) else {
            throw SecretsServiceError.itemAbsent
        }

        return try T.fromDataStoredInSecrets(data)
    }

    func deleteAllItems() throws {
        for item in SecretsService.Item.allCases {
            switch item.kind {
            case .genericPassword:
                try keychainService.deleteGenericPassword(
                    account: key(item: item),
                    service: Self.keychainServiceName)
            case .key:
                try keychainService.deleteKey(applicationTag: key(item: item))
            }
        }
    }

    func generatePushKeyAndReturnPublicKey() throws -> Data {
        try keychainService.generateKeyAndReturnPublicKey(
            applicationTag: key(item: .pushKey),
            attributes: PushKey.attributes)
    }

    func getPushKey() throws -> Data? {
        try keychainService.getPrivateKey(
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

private extension SecretsService {
    static let keychainServiceName = "com.metabolist.metatext"

    func key(item: Item) -> String {
        identityID.uuidString + "." + item.rawValue
    }
}

extension Data: SecretsStorable {
    var dataStoredInSecrets: Data { self }

    static func fromDataStoredInSecrets(_ data: Data) throws -> Data {
        data
    }
}

extension String: SecretsStorable {
    var dataStoredInSecrets: Data { Data(utf8) }

    static func fromDataStoredInSecrets(_ data: Data) throws -> String {
        guard let string = String(data: data, encoding: .utf8) else {
            throw SecretsStorableError.conversionFromDataStoredInSecrets(data)
        }

        return string
    }
}

struct PushKey {
    static let authLength = 16
    static let sizeInBits = 256
    static let attributes: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
        kSecAttrKeySizeInBits as String: sizeInBits]
}
