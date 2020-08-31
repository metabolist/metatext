import Foundation
import HTTP
import Services
import Stubbing

extension AppEnvironment {
    static let mock = AppEnvironment(
        session: Session(configuration: .stubbing),
        webAuthSessionType: SuccessfulMockWebAuthSession.self,
        keychainServiceType: MockKeychainService.self,
        userDefaults: MockUserDefaults(),
        inMemoryContent: true)
}
