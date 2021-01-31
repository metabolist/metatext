// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct TimelineRecord: ContentDatabaseRecord, Hashable {
    let id: Timeline.Id
    let listId: List.Id?
    let listTitle: String?
    let tag: String?
    let accountId: Account.Id?
    let profileCollection: ProfileCollection?
}

extension TimelineRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let listId = Column(CodingKeys.listId)
        static let listTitle = Column(CodingKeys.listTitle)
        static let tag = Column(CodingKeys.tag)
        static let accountId = Column(CodingKeys.accountId)
        static let profileCollection = Column(CodingKeys.profileCollection)
    }

    static let statusJoins = hasMany(TimelineStatusJoin.self)
    static let statuses = hasMany(
        StatusRecord.self,
        through: statusJoins,
        using: TimelineStatusJoin.status)
        .order(StatusRecord.Columns.id.desc)
    static let orderedStatuses = hasMany(
        StatusRecord.self,
        through: statusJoins.order(TimelineStatusJoin.Columns.order),
        using: TimelineStatusJoin.status)
    static let account = belongsTo(AccountRecord.self, using: ForeignKey([Columns.accountId]))
    static let loadMores = hasMany(LoadMoreRecord.self)

    var statuses: QueryInterfaceRequest<StatusInfo> {
        StatusInfo.request(request(for: Self.statuses))
    }

    var orderedStatuses: QueryInterfaceRequest<StatusInfo> {
        StatusInfo.request(request(for: Self.orderedStatuses))
    }

    var loadMores: QueryInterfaceRequest<LoadMoreRecord> {
        request(for: Self.loadMores)
    }

    init(timeline: Timeline) {
        id = timeline.id

        switch timeline {
        case .home, .local, .federated, .favorites, .bookmarks:
            listId = nil
            listTitle = nil
            tag = nil
            accountId = nil
            profileCollection = nil
        case let .list(list):
            listId = list.id
            listTitle = list.title
            tag = nil
            accountId = nil
            profileCollection = nil
        case let .tag(tag):
            listId = nil
            listTitle = nil
            self.tag = tag
            accountId = nil
            profileCollection = nil
        case let .profile(accountId, profileCollection):
            listId = nil
            listTitle = nil
            tag = nil
            self.accountId = accountId
            self.profileCollection = profileCollection
        }
    }
}
