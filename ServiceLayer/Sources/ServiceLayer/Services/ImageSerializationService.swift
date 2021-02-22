// Copyright © 2020 Metabolist. All rights reserved.

import Base16
import CryptoKit
import Foundation
import Secrets

public struct ImageSerializationService {
    private let key: SymmetricKey

    public init(environment: AppEnvironment) throws {
        key = try SymmetricKey(data: Secrets.imageCacheKey(keychain: environment.keychain))
    }
}

public extension ImageSerializationService {
    func serialize(data: Data) throws -> Data {
        try ChaChaPoly.seal(data, using: key).combined
    }

    func deserialize(data: Data) throws -> Data {
        try ChaChaPoly.open(.init(combined: data), using: key)
    }

    func cacheKey(forKey key: String) -> String {
        Data(SHA256.hash(data: Data(key.utf8))).base16EncodedString()
    }
}
