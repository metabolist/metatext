// Copyright © 2020 Metabolist. All rights reserved.

import XCTest
import Combine
import CombineExpectations
@testable import Metatext

class AddIdentityViewModelTests: XCTestCase {
    func testAddIdentity() throws {
        let identityDatabase = IdentityDatabase.fresh()
        let sut = AddIdentityViewModel(identitiesService: .fresh(identityDatabase: identityDatabase))
        let addedIDRecorder = sut.addedIdentityID.record()

        sut.urlFieldText = "https://mastodon.social"
        sut.logInTapped()

        let addedIdentityID = try wait(for: addedIDRecorder.next(), timeout: 1)
        let identityRecorder = identityDatabase.identityObservation(id: addedIdentityID).record()
        let addedIdentity = try wait(for: identityRecorder.next(), timeout: 1)

        XCTAssertEqual(addedIdentity.id, addedIdentityID)
        XCTAssertEqual(addedIdentity.url, URL(string: "https://mastodon.social")!)
    }

    func testAddIdentityWithoutScheme() throws {
        let identityDatabase = IdentityDatabase.fresh()
        let sut = AddIdentityViewModel(identitiesService: .fresh(identityDatabase: identityDatabase))
        let addedIDRecorder = sut.addedIdentityID.record()

        sut.urlFieldText = "mastodon.social"
        sut.logInTapped()

        let addedIdentityID = try wait(for: addedIDRecorder.next(), timeout: 1)
        let identityRecorder = identityDatabase.identityObservation(id: addedIdentityID).record()
        let addedIdentity = try wait(for: identityRecorder.next(), timeout: 1)

        XCTAssertEqual(addedIdentity.id, addedIdentityID)
        XCTAssertEqual(addedIdentity.url, URL(string: "https://mastodon.social")!)
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
            URLSessionConfiguration: .stubbing,
            webAuthSessionType: CanceledLoginMockWebAuthSession.self)
        let identitiesService = IdentitiesService(
            identityDatabase: .fresh(),
            keychainService: MockKeychainService(),
            environment: environment)
        let sut = AddIdentityViewModel(identitiesService: identitiesService)
        let recorder = sut.$alertItem.record()

        XCTAssertNil(try wait(for: recorder.next(), timeout: 1))

        sut.urlFieldText = "https://mastodon.social"
        sut.logInTapped()

        try wait(for: recorder.next().inverted, timeout: 1)
    }
}
