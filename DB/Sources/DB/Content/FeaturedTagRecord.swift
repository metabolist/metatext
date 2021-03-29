// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct FeaturedTagRecord: ContentDatabaseRecord, Hashable {
    let id: FeaturedTag.Id
    let name: String
    let url: UnicodeURL
    let statusesCount: Int
    let lastStatusAt: Date
    let accountId: Account.Id
}

extension FeaturedTagRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let url = Column(CodingKeys.url)
        static let statusesCount = Column(CodingKeys.statusesCount)
        static let lastStatusAt = Column(CodingKeys.lastStatusAt)
        static let accountId = Column(CodingKeys.accountId)
    }
}
