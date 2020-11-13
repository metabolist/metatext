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
        static let id = Column(CodingKeys.id)
        static let url = Column(CodingKeys.url)
        static let authenticated = Column(CodingKeys.authenticated)
        static let pending = Column(CodingKeys.pending)
        static let lastUsedAt = Column(CodingKeys.lastUsedAt)
        static let preferences = Column(CodingKeys.preferences)
        static let instanceURI = Column(CodingKeys.instanceURI)
        static let lastRegisteredDeviceToken = Column(CodingKeys.lastRegisteredDeviceToken)
        static let pushSubscriptionAlerts = Column(CodingKeys.pushSubscriptionAlerts)
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
