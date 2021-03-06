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
    let reduceMotion: () -> Bool
    let autoplayVideos: () -> Bool
    let uuid: () -> UUID
    let inMemoryContent: Bool
    let fixtureDatabase: IdentityDatabase?

    public init(session: URLSession,
                webAuthSessionType: WebAuthSession.Type,
                keychain: Keychain.Type,
                userDefaults: UserDefaults,
                userNotificationClient: UserNotificationClient,
                reduceMotion: @escaping () -> Bool,
                autoplayVideos: @escaping () -> Bool,
                uuid: @escaping () -> UUID,
                inMemoryContent: Bool,
                fixtureDatabase: IdentityDatabase?) {
        self.session = session
        self.webAuthSessionType = webAuthSessionType
        self.keychain = keychain
        self.userDefaults = userDefaults
        self.userNotificationClient = userNotificationClient
        self.reduceMotion = reduceMotion
        self.autoplayVideos = autoplayVideos
        self.uuid = uuid
        self.inMemoryContent = inMemoryContent
        self.fixtureDatabase = fixtureDatabase
    }
}

public extension AppEnvironment {
    static let appGroup = "group.metabolist.metatext"

    static func live(userNotificationCenter: UNUserNotificationCenter,
                     reduceMotion: @escaping () -> Bool,
                     autoplayVideos: @escaping () -> Bool) -> Self {
        Self(
            session: URLSession.shared,
            webAuthSessionType: LiveWebAuthSession.self,
            keychain: LiveKeychain.self,
            userDefaults: UserDefaults(suiteName: appGroup)!,
            userNotificationClient: .live(userNotificationCenter),
            reduceMotion: reduceMotion,
            autoplayVideos: autoplayVideos,
            uuid: UUID.init,
            inMemoryContent: false,
            fixtureDatabase: nil)
    }
}
