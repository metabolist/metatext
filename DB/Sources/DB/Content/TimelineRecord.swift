// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct TimelineRecord: Codable, Hashable {
    let id: String
    let listId: String?
    let listTitle: String?
    let tag: String?
    let accountId: String?
    let profileCollection: ProfileCollection?
}

extension TimelineRecord: FetchableRecord, PersistableRecord {
    static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        MastodonDecoder()
    }

    static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        MastodonEncoder()
    }
}

extension TimelineRecord {
    enum Columns {
        static let id = Column(TimelineRecord.CodingKeys.id)
        static let listId = Column(TimelineRecord.CodingKeys.listId)
        static let listTitle = Column(TimelineRecord.CodingKeys.listTitle)
        static let tag = Column(TimelineRecord.CodingKeys.tag)
        static let accountId = Column(TimelineRecord.CodingKeys.accountId)
        static let profileCollection = Column(TimelineRecord.CodingKeys.profileCollection)
    }

    static let statusJoins = hasMany(TimelineStatusJoin.self)
    static let statuses = hasMany(
        StatusRecord.self,
        through: statusJoins,
        using: TimelineStatusJoin.status)
        .order(StatusRecord.Columns.createdAt.desc)
    static let loadMores = hasMany(LoadMore.self)

    var statuses: QueryInterfaceRequest<StatusInfo> {
        StatusInfo.request(request(for: Self.statuses))
    }

    var loadMores: QueryInterfaceRequest<LoadMore> {
        request(for: Self.loadMores)
    }

    init(timeline: Timeline) {
        id = timeline.id

        switch timeline {
        case .home, .local, .federated:
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
