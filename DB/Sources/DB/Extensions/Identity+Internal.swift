// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

extension Identity {
    init(info: IdentityInfo) {
        self.init(
            id: info.identity.id,
            url: info.identity.url,
            authenticated: info.identity.authenticated,
            pending: info.identity.pending,
            lastUsedAt: info.identity.lastUsedAt,
            preferences: info.identity.preferences,
            instance: info.instance,
            account: info.account,
            lastRegisteredDeviceToken: info.identity.lastRegisteredDeviceToken,
            pushSubscriptionAlerts: info.identity.pushSubscriptionAlerts)
    }
}

extension Identity.Instance: FetchableRecord, PersistableRecord {}

extension Identity.Account: FetchableRecord, PersistableRecord {}
