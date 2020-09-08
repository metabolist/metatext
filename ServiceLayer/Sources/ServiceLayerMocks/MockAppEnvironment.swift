// Copyright © 2020 Metabolist. All rights reserved.

import DB
import Foundation
import HTTP
import Keychain
import MockKeychain
import ServiceLayer
import Stubbing

public extension AppEnvironment {
    static func mock(session: Session = Session(configuration: .stubbing),
                     webAuthSessionType: WebAuthSession.Type = SuccessfulMockWebAuthSession.self,
                     keychain: Keychain.Type = MockKeychain.self,
                     userDefaults: UserDefaults = MockUserDefaults(),
                     userNotificationClient: UserNotificationClient = .mock,
                     inMemoryContent: Bool = true,
                     fixtureDatabase: IdentityDatabase? = nil) -> Self {
        AppEnvironment(
            session: Session(configuration: .stubbing),
            webAuthSessionType: SuccessfulMockWebAuthSession.self,
            keychain: MockKeychain.self,
            userDefaults: MockUserDefaults(),
            userNotificationClient: .mock,
            inMemoryContent: true,
            fixtureDatabase: fixtureDatabase)
    }
}
