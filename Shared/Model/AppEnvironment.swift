// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct AppEnvironment {
    let session: Session
    let webAuthSessionType: WebAuthSession.Type
    let keychainServiceType: KeychainService.Type
    let userDefaults: UserDefaults = .standard
}

extension AppEnvironment {
    static let live: Self = Self(
        session: Session(configuration: .default),
        webAuthSessionType: LiveWebAuthSession.self,
        keychainServiceType: LiveKeychainService.self)
}
