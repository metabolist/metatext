// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Timeline: FetchableRecord, PersistableRecord {
    enum Columns: String, ColumnExpression {
        case id
        case listTitle
    }

    public init(row: Row) {
        switch (row[Columns.id] as String, row[Columns.listTitle] as String?) {
        case (Timeline.home.id, _):
            self = .home
        case (Timeline.local.id, _):
            self = .local
        case (Timeline.federated.id, _):
            self = .federated
        case (let id, .some(let title)):
            self = .list(List(id: id, title: title))
        default:
            var tag: String = row[Columns.id]

            tag.removeFirst()
            self = .tag(tag)
        }
    }

    public func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id

        if case let .list(list) = self {
            container[Columns.listTitle] = list.title
        }
    }
}

extension Timeline {
    static let statusJoins = hasMany(TimelineStatusJoin.self)
    static let statuses = hasMany(
        StatusRecord.self,
        through: statusJoins,
        using: TimelineStatusJoin.status)
        .order(StatusRecord.Columns.createdAt.desc)

    var statuses: QueryInterfaceRequest<StatusResult> {
        request(for: Self.statuses).statusResultRequest
    }
}
