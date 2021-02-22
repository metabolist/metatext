// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import SDWebImage
import ServiceLayer

final class ImageDiskCache: SDDiskCache {
    static var service: ImageSerializationService?

    private let cachePath: String

    required init?(cachePath: String, config: SDImageCacheConfig) {
        self.cachePath = cachePath

        super.init(cachePath: cachePath, config: config)
    }

    override func data(forKey key: String) -> Data? {
        guard let data = super.data(forKey: key) else { return nil }

        return try? Self.service?.deserialize(data: data)
    }

    override func setData(_ data: Data?, forKey key: String) {
        guard let data = data else {
            super.setData(nil, forKey: key)

            return
        }

        super.setData(try? Self.service?.serialize(data: data), forKey: key)
    }

    override func cachePath(forKey key: String) -> String? {
        guard let service = Self.service else { return super.cachePath(forKey: key) }

        return (cachePath as NSString).appendingPathComponent(service.cacheKey(forKey: key))
    }
}
