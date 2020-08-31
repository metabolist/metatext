import Foundation
import HTTP
import ServiceLayer
import Stubbing

public extension AppEnvironment {
    static let mock = AppEnvironment(
        session: Session(configuration: .stubbing),
        webAuthSessionType: SuccessfulMockWebAuthSession.self,
        keychainServiceType: MockKeychainService.self,
        userDefaults: MockUserDefaults(),
        inMemoryContent: true)
}
