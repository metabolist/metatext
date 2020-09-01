// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import ServiceLayer
import Stubbing

public extension AppEnvironment {
    static func mock(identityFixture: IdentityFixture? = nil) -> Self {
        AppEnvironment(
            session: Session(configuration: .stubbing),
            webAuthSessionType: SuccessfulMockWebAuthSession.self,
            keychainServiceType: MockKeychainService.self,
            userDefaults: MockUserDefaults(),
            userNotificationClient: .mock,
            inMemoryContent: true,
            identityFixture: identityFixture)
    }
}
