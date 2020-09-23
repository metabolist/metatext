// Copyright © 2020 Metabolist. All rights reserved.

import DB
import Foundation
import HTTP
import Keychain
import Mastodon
import UserNotifications

public struct AppEnvironment {
    let session: URLSession
    let webAuthSessionType: WebAuthSession.Type
    let keychain: Keychain.Type
    let userDefaults: UserDefaults
    let userNotificationClient: UserNotificationClient
    let uuid: () -> UUID
    let inMemoryContent: Bool
    let fixtureDatabase: IdentityDatabase?

    public init(session: URLSession,
                webAuthSessionType: WebAuthSession.Type,
                keychain: Keychain.Type,
                userDefaults: UserDefaults,
                userNotificationClient: UserNotificationClient,
                uuid: @escaping () -> UUID,
                inMemoryContent: Bool,
                fixtureDatabase: IdentityDatabase?) {
        self.session = session
        self.webAuthSessionType = webAuthSessionType
        self.keychain = keychain
        self.userDefaults = userDefaults
        self.userNotificationClient = userNotificationClient
        self.uuid = uuid
        self.inMemoryContent = inMemoryContent
        self.fixtureDatabase = fixtureDatabase
    }
}

public extension AppEnvironment {
    static func live(userNotificationCenter: UNUserNotificationCenter) -> Self {
        Self(
            session: URLSession.shared,
            webAuthSessionType: LiveWebAuthSession.self,
            keychain: LiveKeychain.self,
            userDefaults: .standard,
            userNotificationClient: .live(userNotificationCenter),
            uuid: UUID.init,
            inMemoryContent: false,
            fixtureDatabase: nil)
    }
}
