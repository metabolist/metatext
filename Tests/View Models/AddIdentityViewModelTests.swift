// Copyright © 2020 Metabolist. All rights reserved.

import XCTest
import Combine
import CombineExpectations
@testable import Metatext

class AddIdentityViewModelTests: XCTestCase {
    func testAddIdentity() throws {
        let identityDatabase = IdentityDatabase.fresh()
        let sut = AddIdentityViewModel(identitiesService: .fresh(identityDatabase: identityDatabase))
        let addedIDAndURLRecorder = sut.addedIdentityIDAndURL.record()

        sut.urlFieldText = "https://mastodon.social"
        sut.logInTapped()

        let addedIdentityIDAndURL = try wait(for: addedIDAndURLRecorder.next(), timeout: 1)

//        XCTAssertEqual(addedIdentityIDAndURL.0, addedIdentityID)
        XCTAssertEqual(addedIdentityIDAndURL.1, URL(string: "https://mastodon.social")!)
    }

    func testAddIdentityWithoutScheme() throws {
        let identityDatabase = IdentityDatabase.fresh()
        let sut = AddIdentityViewModel(identitiesService: .fresh(identityDatabase: identityDatabase))
        let addedIDAndURLRecorder = sut.addedIdentityIDAndURL.record()

        sut.urlFieldText = "mastodon.social"
        sut.logInTapped()

        let addedIdentityIDAndURL = try wait(for: addedIDAndURLRecorder.next(), timeout: 1)

//        XCTAssertEqual(addedIdentityIDAndURL.0, addedIdentityID)
        XCTAssertEqual(addedIdentityIDAndURL.1, URL(string: "https://mastodon.social")!)
    }

    func testInvalidURL() throws {
        let sut = AddIdentityViewModel(identitiesService: .fresh())
        let recorder = sut.$alertItem.record()

        XCTAssertNil(try wait(for: recorder.next(), timeout: 1))

        sut.urlFieldText = "🐘.social"
        sut.logInTapped()

        let alertItem = try wait(for: recorder.next(), timeout: 1)

        XCTAssertEqual((alertItem?.error as? URLError)?.code, URLError.badURL)
    }

    func testDoesNotAlertCanceledLogin() throws {
        let environment = AppEnvironment(
            session: Session(configuration: .stubbing),
            webAuthSessionType: CanceledLoginMockWebAuthSession.self,
            keychainServiceType: MockKeychainService.self)
        let identitiesService = IdentitiesService(
            identityDatabase: .fresh(),
            environment: environment)
        let sut = AddIdentityViewModel(identitiesService: identitiesService)
        let recorder = sut.$alertItem.record()

        XCTAssertNil(try wait(for: recorder.next(), timeout: 1))

        sut.urlFieldText = "https://mastodon.social"
        sut.logInTapped()

        try wait(for: recorder.next().inverted, timeout: 1)
    }
}
