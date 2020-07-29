// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

typealias FakeKeychain = [String: Data]

extension FakeKeychain: KeychainType {
    mutating func set(data: Data, forKey key: String) throws {
        self[key] = data
    }

    mutating func deleteData(key: String) throws {
        self[key] = nil
    }

    func getData(key: String) throws -> Data? {
        self[key]
    }
}
