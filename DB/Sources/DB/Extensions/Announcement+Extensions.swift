// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Announcement: ContentDatabaseRecord {}

extension Announcement {
    enum Columns: String, ColumnExpression {
        case id
        case content
        case startsAt
        case endsAt
        case allDay
        case publishedAt
        case updatedAt
        case read
        case mentions
        case tags
        case emojis
        case reactions
    }
}
