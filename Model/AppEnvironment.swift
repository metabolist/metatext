// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

struct AppEnvironment {
    let session: Session
    let webAuthSessionType: WebAuthSession.Type
    let keychainServiceType: KeychainService.Type
    let userDefaults: UserDefaults
    let inMemoryContent: Bool
}

extension AppEnvironment {
    static let live: Self = Self(
        session: Session(configuration: .default),
        webAuthSessionType: LiveWebAuthSession.self,
        keychainServiceType: LiveKeychainService.self,
        userDefaults: .standard,
        inMemoryContent: false)
}
