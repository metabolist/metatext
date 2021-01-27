// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension MastodonNotification {
    func save(_ db: Database) throws {
        try account.save(db)
        try status?.save(db)
        try NotificationRecord(notification: self).save(db)
    }

    init(info: NotificationInfo) {
        let status: Status?

        if let statusInfo = info.statusInfo {
            status = .init(info: statusInfo)
        } else {
            status = nil
        }

        self.init(
            id: info.record.id,
            type: info.record.type,
            account: .init(info: info.accountInfo),
            createdAt: info.record.createdAt,
            status: status)
    }
}
