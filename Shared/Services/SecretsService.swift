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
    private let keychainServiceType: KeychainService.Type

    init(identityID: UUID, keychainServiceType: KeychainService.Type) {
        self.identityID = identityID
        self.keychainServiceType = keychainServiceType
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

extension SecretsService {
    func set(_ data: SecretsStorable, forItem item: Item) throws {
        try keychainServiceType.setGenericPassword(
            data: data.dataStoredInSecrets,
            forAccount: key(item: item),
            service: Self.keychainServiceName)
    }

    func item<T: SecretsStorable>(_ item: Item) throws -> T? {
        guard let data = try keychainServiceType.getGenericPassword(
                account: key(item: item),
                service: Self.keychainServiceName) else {
            return nil
        }

        return try T.fromDataStoredInSecrets(data)
    }

    func deleteAllItems() throws {
        for item in SecretsService.Item.allCases {
            try keychainServiceType.deleteGenericPassword(
                account: key(item: item),
                service: Self.keychainServiceName)
        }
    }

    func generatePushKeyAndReturnPublicKey() throws -> Data {
        try keychainServiceType.generateKeyAndReturnPublicKey(applicationTag: key(item: .pushKey))
    }

    func getPushKey() throws -> Data? {
        try keychainServiceType.getPrivateKey(applicationTag: key(item: .pushKey))
    }

    func generatePushAuth() throws -> Data {
        var bytes = [UInt8](repeating: 0, count: Self.authLength)

        _ = SecRandomCopyBytes(kSecRandomDefault, Self.authLength, &bytes)

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
    private static let authLength = 16

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
