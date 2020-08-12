// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct MockKeychainService {}

extension MockKeychainService {
    static func reset() {
        items = [String: Data]()
    }
}

extension MockKeychainService: KeychainServiceType {
    static func setGenericPassword(data: Data, forAccount key: String, service: String) throws {
        items[key] = data
    }

    static func deleteGenericPassword(account: String, service: String) throws {
        items[account] = nil
    }

    static func getGenericPassword(account: String, service: String) throws -> Data? {
        items[account]
    }

    static func generateKeyAndReturnPublicKey(applicationTag: String) throws -> Data {
        fatalError("not implemented")
    }

    static func getPrivateKey(applicationTag: String) throws -> Data? {
        fatalError("not implemented")
    }
}

private extension MockKeychainService {
    static var items = [String: Data]()
}
