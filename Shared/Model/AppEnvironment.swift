// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct AppEnvironment {
    let URLSessionConfiguration: URLSessionConfiguration
    let identityDatabase: IdentityDatabase
    let defaults: Defaults
    let keychainService: KeychainServiceType
    let webAuthSessionType: WebAuthSessionType.Type
}
