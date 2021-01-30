// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Instance {
    func save(_ db: Database) throws {
        if let contactAccount = contactAccount {
            try AccountRecord(account: contactAccount).save(db)
        }

        try InstanceRecord(instance: self).save(db)
    }

    init(info: InstanceInfo) {
        var contactAccount: Account?

        if let contactAccountInfo = info.contactAccountInfo {
            contactAccount = Account(info: contactAccountInfo)
        }

        self.init(record: info.record, contactAccount: contactAccount)
    }
}

private extension Instance {
    init(record: InstanceRecord, contactAccount: Account?) {
        self.init(uri: record.uri,
                  title: record.title,
                  description: record.description,
                  shortDescription: record.shortDescription,
                  email: record.email,
                  version: record.version,
                  urls: record.urls,
                  stats: record.stats,
                  thumbnail: record.thumbnail,
                  contactAccount: contactAccount,
                  maxTootChars: record.maxTootChars)
    }
}
