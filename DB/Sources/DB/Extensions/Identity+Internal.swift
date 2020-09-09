// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

extension Identity {
    init(result: IdentityResult) {
        self.init(
            id: result.identity.id,
            url: result.identity.url,
            authenticated: result.identity.authenticated,
            lastUsedAt: result.identity.lastUsedAt,
            preferences: result.identity.preferences,
            instance: result.instance,
            account: result.account,
            lastRegisteredDeviceToken: result.identity.lastRegisteredDeviceToken,
            pushSubscriptionAlerts: result.pushSubscriptionAlerts)
    }
}

extension Identity.Instance: FetchableRecord, PersistableRecord {}

extension Identity.Account: FetchableRecord, PersistableRecord {}
