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
    private let keychainService: KeychainServiceType

    init(identityID: UUID, keychainService: KeychainServiceType) {
        self.identityID = identityID
        self.keychainService = keychainService
    }
}

extension SecretsService {
    enum Item: String, CaseIterable {
        case clientID = "client-id"
        case clientSecret = "client-secret"
        case accessToken = "access-token"
    }
}

extension SecretsService {
    func set(_ data: SecretsStorable, forItem item: Item) throws {
        try keychainService.set(data: data.dataStoredInSecrets, forKey: key(item: item))
    }

    func item<T: SecretsStorable>(_ item: Item) throws -> T? {
        guard let data = try keychainService.getData(key: key(item: item)) else {
            return nil
        }

        return try T.fromDataStoredInSecrets(data)
    }

    func deleteAllItems() throws {
        for item in SecretsService.Item.allCases {
            try keychainService.deleteData(key: key(item: item))
        }
    }
}

private extension SecretsService {
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
