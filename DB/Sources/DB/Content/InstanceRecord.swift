// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct InstanceRecord: ContentDatabaseRecord, Hashable {
    let uri: String
    let title: String
    let description: String
    let shortDescription: String?
    let email: String
    let version: String
    let languages: [String]
    let registrations: Bool
    let approvalRequired: Bool
    let invitesEnabled: Bool
    let urls: Instance.URLs
    let stats: Instance.Stats
    let thumbnail: UnicodeURL?
    let contactAccountId: Account.Id?
    let maxTootChars: Int?
}

extension InstanceRecord {
    enum Columns {
        static let uri = Column(CodingKeys.uri)
        static let title = Column(CodingKeys.title)
        static let description = Column(CodingKeys.description)
        static let shortDescription = Column(CodingKeys.shortDescription)
        static let email = Column(CodingKeys.email)
        static let version = Column(CodingKeys.version)
        static let languages = Column(CodingKeys.languages)
        static let registrations = Column(CodingKeys.registrations)
        static let approvalRequired = Column(CodingKeys.approvalRequired)
        static let invitesEnabled = Column(CodingKeys.invitesEnabled)
        static let urls = Column(CodingKeys.urls)
        static let stats = Column(CodingKeys.stats)
        static let thumbnail = Column(CodingKeys.thumbnail)
        static let contactAccountId = Column(CodingKeys.contactAccountId)
        static let maxTootChars = Column(CodingKeys.maxTootChars)
    }

    static let contactAccount = belongsTo(AccountRecord.self)

    init(instance: Instance) {
        self.uri = instance.uri
        self.title = instance.title
        self.description = instance.description
        self.shortDescription = instance.shortDescription
        self.email = instance.email
        self.version = instance.version
        self.languages = instance.languages
        self.registrations = instance.registrations
        self.approvalRequired = instance.approvalRequired
        self.invitesEnabled = instance.invitesEnabled
        self.urls = instance.urls
        self.stats = instance.stats
        self.thumbnail = instance.thumbnail
        self.contactAccountId = instance.contactAccount?.id
        self.maxTootChars = instance.maxTootChars
    }
}
