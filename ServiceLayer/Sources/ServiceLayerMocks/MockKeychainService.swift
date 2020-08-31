// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import ServiceLayer

public struct MockKeychainService {}

public extension MockKeychainService {
    static func reset() {
        items = [String: Data]()
    }
}

extension MockKeychainService: KeychainService {
    public static func setGenericPassword(data: Data, forAccount key: String, service: String) throws {
        items[key] = data
    }

    public static func deleteGenericPassword(account: String, service: String) throws {
        items[account] = nil
    }

    public static func getGenericPassword(account: String, service: String) throws -> Data? {
        items[account]
    }

    public static func generateKeyAndReturnPublicKey(applicationTag: String, attributes: [String: Any]) throws -> Data {
        fatalError("not implemented")
    }

    public static func getPrivateKey(applicationTag: String, attributes: [String: Any]) throws -> Data? {
        fatalError("not implemented")
    }

    public static func deleteKey(applicationTag: String) throws {
        fatalError("not implemented")
    }
}

private extension MockKeychainService {
    static var items = [String: Data]()
}
