// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

public struct EmojiUse: ContentDatabaseRecord, Hashable {
    public let emoji: String
    public let system: Bool
    public let lastUse: Date
    public let count: Int
}

extension EmojiUse {
    enum Columns {
        static let emoji = Column(CodingKeys.emoji)
        static let system = Column(CodingKeys.system)
        static let lastUse = Column(CodingKeys.lastUse)
        static let count = Column(CodingKeys.count)
    }
}
