// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

protocol SecretsStorable {
    var dataStoredInSecrets: Data { get }
    static func fromDataStoredInSecrets(_ data: Data) throws -> Self
}

enum SecretsStorableError: Error {
    case conversionFromDataStoredInSecrets(Data)
}

class Secrets {
    private var keychain: KeychainType

    init(keychain: KeychainType) {
        self.keychain = keychain
    }
}

extension Secrets {
    enum Item: String {
        case clientID = "client-id"
        case clientSecret = "client-secret"
        case accessToken = "access-token"
    }
}

extension Secrets {
    func set(_ data: SecretsStorable, forItem item: Item, forIdentityID identityID: UUID) throws {
        try keychain.set(data: data.dataStoredInSecrets, forKey: Self.key(item: item, identityID: identityID))
    }

    func item<T: SecretsStorable>(_ item: Item, forIdentityID identityID: UUID) throws -> T? {
        guard let data = try keychain.getData(key: Self.key(item: item, identityID: identityID)) else { return nil }

        return try T.fromDataStoredInSecrets(data)
    }

    func delete(_ item: Item, forIdentityID identityID: UUID) throws {
        try keychain.deleteData(key: Self.key(item: item, identityID: identityID))
    }
}

private extension Secrets {
    static func key(item: Item, identityID: UUID) -> String {
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
