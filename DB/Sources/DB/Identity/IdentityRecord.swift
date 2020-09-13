// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct IdentityRecord: Codable, Hashable, FetchableRecord, PersistableRecord {
    let id: UUID
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
    static let instance = belongsTo(Identity.Instance.self, key: "instance")
    static let account = hasOne(Identity.Account.self, key: "account")

    var instance: QueryInterfaceRequest<Identity.Instance> {
        request(for: Self.instance)
    }

    var account: QueryInterfaceRequest<Identity.Account> {
        request(for: Self.account)
    }
}
