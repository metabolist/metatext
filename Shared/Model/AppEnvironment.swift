// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct AppEnvironment {
    let URLSessionConfiguration: URLSessionConfiguration
    let identityDatabase: IdentityDatabase
    let defaults: Defaults
    let secrets: Secrets
    let webAuthSessionType: WebAuthSession.Type
}
