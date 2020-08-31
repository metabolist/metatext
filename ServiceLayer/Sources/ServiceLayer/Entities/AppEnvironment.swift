// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public struct AppEnvironment {
    let session: Session
    let webAuthSessionType: WebAuthSession.Type
    let keychainServiceType: KeychainService.Type
    let userDefaults: UserDefaults
    let inMemoryContent: Bool

    public init(session: Session,
                webAuthSessionType: WebAuthSession.Type,
                keychainServiceType: KeychainService.Type,
                userDefaults: UserDefaults,
                inMemoryContent: Bool) {
        self.session = session
        self.webAuthSessionType = webAuthSessionType
        self.keychainServiceType = keychainServiceType
        self.userDefaults = userDefaults
        self.inMemoryContent = inMemoryContent
    }
}

public extension AppEnvironment {
    static let live: Self = Self(
        session: Session(configuration: .default),
        webAuthSessionType: LiveWebAuthSession.self,
        keychainServiceType: LiveKeychainService.self,
        userDefaults: .standard,
        inMemoryContent: false)
}
