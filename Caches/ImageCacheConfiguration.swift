// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import Kingfisher
import ServiceLayer

struct ImageCacheConfiguration {
    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }
}

extension ImageCacheConfiguration {
    func configure() throws {
        KingfisherManager.shared.cache = try ImageCache(
            name: Self.name,
            cacheDirectoryURL: Self.directoryURL)
        try KingfisherManager.shared.defaultOptions = [
            .cacheSerializer(ImageCacheSerializer(service: .init(environment: environment)))
        ]
    }
}

private extension ImageCacheConfiguration {
    static let name = "Images"
    static let directoryURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: AppEnvironment.appGroup)?
        .appendingPathComponent("Library")
        .appendingPathComponent("Caches")
}
