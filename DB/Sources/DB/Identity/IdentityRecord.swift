// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct IdentityRecord: Codable, Hashable, FetchableRecord, PersistableRecord {
    let id: Identity.Id
    let url: URL
    let authenticated: Bool
    let pending: Bool
    let lastUsedAt: Date
    let preferences: Identity.Preferences
    let instanceURI: String?
    let lastRegisteredDeviceToken: Data?
    let pushSubscriptionAlerts: PushSubscription.Alerts
}

extension IdentityRecord {
    enum Columns {
        static let id = Column(IdentityRecord.CodingKeys.id)
        static let url = Column(IdentityRecord.CodingKeys.url)
        static let authenticated = Column(IdentityRecord.CodingKeys.authenticated)
        static let pending = Column(IdentityRecord.CodingKeys.pending)
        static let lastUsedAt = Column(IdentityRecord.CodingKeys.lastUsedAt)
        static let preferences = Column(IdentityRecord.CodingKeys.preferences)
        static let instanceURI = Column(IdentityRecord.CodingKeys.instanceURI)
        static let lastRegisteredDeviceToken = Column(IdentityRecord.CodingKeys.lastRegisteredDeviceToken)
        static let pushSubscriptionAlerts = Column(IdentityRecord.CodingKeys.pushSubscriptionAlerts)
    }

    static let instance = belongsTo(Identity.Instance.self)
    static let account = hasOne(Identity.Account.self)

    var instance: QueryInterfaceRequest<Identity.Instance> {
        request(for: Self.instance)
    }

    var account: QueryInterfaceRequest<Identity.Account> {
        request(for: Self.account)
    }
}
