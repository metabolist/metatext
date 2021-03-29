// Copyright © 2021 Metabolist. All rights reserved.

import Foundation

public struct FeaturedTag: Codable, Hashable {
    public let id: Id
    public let name: String
    public let url: UnicodeURL
    public let statusesCount: Int
    public let lastStatusAt: Date

    public init(id: FeaturedTag.Id, name: String, url: UnicodeURL, statusesCount: Int, lastStatusAt: Date) {
        self.id = id
        self.name = name
        self.url = url
        self.statusesCount = statusesCount
        self.lastStatusAt = lastStatusAt
    }
}

public extension FeaturedTag {
    typealias Id = String
}
