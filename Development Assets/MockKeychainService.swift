// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class MockKeychainService {
    private var items = [String: Data]()
}

extension MockKeychainService: KeychainServiceType {
    func set(data: Data, forKey key: String) throws {
        items[key] = data
    }

    func deleteData(key: String) throws {
        items[key] = nil
    }

    func getData(key: String) throws -> Data? {
        items[key]
    }
}
