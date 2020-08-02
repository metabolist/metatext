// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct AppEnvironment {
    let identityDatabase: IdentityDatabase
    let preferences: Preferences
    let secrets: Secrets
    let webAuthSessionType: WebAuthSession.Type
}
