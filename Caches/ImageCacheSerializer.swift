// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import Kingfisher
import ServiceLayer

struct ImageCacheSerializer {
    private let service: ImageSerializationService

    init(service: ImageSerializationService) {
        self.service = service
    }
}

extension ImageCacheSerializer: CacheSerializer {
    func data(with image: KFCrossPlatformImage, original: Data?) -> Data? {
        guard let data = image.kf.data(format: original?.kf.imageFormat ?? .unknown) else { return nil }

        return try? service.serialize(data: data)
    }

    func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        guard let deserialized = try? service.deserialize(data: data) else { return nil }

        return KingfisherWrapper.image(data: deserialized, options: .init())
    }
}
