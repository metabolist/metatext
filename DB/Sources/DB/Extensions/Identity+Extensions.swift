// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

extension Identity {
    init(info: IdentityInfo) {
        self.init(
            id: info.record.id,
            url: info.record.url,
            authenticated: info.record.authenticated,
            pending: info.record.pending,
            lastUsedAt: info.record.lastUsedAt,
            preferences: info.record.preferences,
            instance: info.instance,
            account: info.account,
            lastRegisteredDeviceToken: info.record.lastRegisteredDeviceToken,
            pushSubscriptionAlerts: info.record.pushSubscriptionAlerts)
    }
}

extension Identity.Instance: FetchableRecord, PersistableRecord {}

extension Identity.Account: FetchableRecord, PersistableRecord {}
