// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct AppEnvironment {
    let URLSessionConfiguration: URLSessionConfiguration
    let identityDatabase: IdentityDatabase
    let preferences: Preferences
    let secrets: Secrets
    let webAuthSessionType: WebAuthSession.Type
}
