// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon
import UserNotifications

public struct AppEnvironment {
    let session: Session
    let webAuthSessionType: WebAuthSession.Type
    let keychainServiceType: KeychainService.Type
    let userDefaults: UserDefaults
    let userNotificationClient: UserNotificationClient
    let inMemoryContent: Bool
    let identityFixture: IdentityFixture?

    public init(session: Session,
                webAuthSessionType: WebAuthSession.Type,
                keychainServiceType: KeychainService.Type,
                userDefaults: UserDefaults,
                userNotificationClient: UserNotificationClient,
                inMemoryContent: Bool,
                identityFixture: IdentityFixture?) {
        self.session = session
        self.webAuthSessionType = webAuthSessionType
        self.keychainServiceType = keychainServiceType
        self.userDefaults = userDefaults
        self.userNotificationClient = userNotificationClient
        self.inMemoryContent = inMemoryContent
        self.identityFixture = identityFixture
    }
}

public extension AppEnvironment {
    struct IdentityFixture {
        public let id: UUID
        public let instanceURL: URL
        public let instance: Instance?
        public let account: Account?

        public init(id: UUID, instanceURL: URL, instance: Instance?, account: Account?) {
            self.id = id
            self.instanceURL = instanceURL
            self.instance = instance
            self.account = account
        }
    }

    static func live(userNotificationCenter: UNUserNotificationCenter) -> Self {
        Self(
            session: Session(configuration: .default),
            webAuthSessionType: LiveWebAuthSession.self,
            keychainServiceType: LiveKeychainService.self,
            userDefaults: .standard,
            userNotificationClient: .live(userNotificationCenter),
            inMemoryContent: false,
            identityFixture: nil)
    }
}
