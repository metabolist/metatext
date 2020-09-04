// Copyright © 2020 Metabolist. All rights reserved.

import DB
import Foundation
import HTTP
import MockKeychain
import ServiceLayer
import Stubbing

public extension AppEnvironment {
    static func mock(identityFixture: IdentityFixture? = nil) -> Self {
        AppEnvironment(
            session: Session(configuration: .stubbing),
            webAuthSessionType: SuccessfulMockWebAuthSession.self,
            keychain: MockKeychain.self,
            userDefaults: MockUserDefaults(),
            userNotificationClient: .mock,
            inMemoryContent: true,
            identityFixture: identityFixture)
    }
}
