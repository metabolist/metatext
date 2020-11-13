// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct StatusShowContentToggle: ContentDatabaseRecord, Hashable {
    let statusId: Status.Id
}

extension StatusShowContentToggle {
    enum Columns {
        static let statusId = Column(CodingKeys.statusId)
    }
}
