// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Timeline {
    init?(record: TimelineRecord) {
        switch (record.id,
                record.listId,
                record.listTitle,
                record.tag,
                record.accountId,
                record.profileCollection) {
        case (Timeline.home.id, _, _, _, _, _):
            self = .home
        case (Timeline.local.id, _, _, _, _, _):
            self = .local
        case (Timeline.federated.id, _, _, _, _, _):
            self = .federated
        case (_, .some(let listId), .some(let listTitle), _, _, _):
            self = .list(List(id: listId, title: listTitle))
        case (_, _, _, .some(let tag), _, _):
            self = .tag(tag)
        case (_, _, _, _, .some(let accountId), .some(let profileCollection)):
            self = .profile(accountId: accountId, profileCollection: profileCollection)
        case (Timeline.favorites.id, _, _, _, _, _):
            self = .favorites
        case (Timeline.bookmarks.id, _, _, _, _, _):
            self = .bookmarks
        default:
            return nil
        }
    }
}
