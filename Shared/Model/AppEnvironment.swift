// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct AppEnvironment {
    let session: Session
    let webAuthSessionType: WebAuthSessionType.Type
    let keychainServiceType: KeychainServiceType.Type
    let userDefaults: UserDefaults = .standard
}

extension AppEnvironment {
    static let live: Self = Self(
        session: Session(configuration: .default),
        webAuthSessionType: WebAuthSession.self,
        keychainServiceType: KeychainService.self)
}
