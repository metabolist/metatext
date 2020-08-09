// Copyright © 2020 Metabolist. All rights reserved.

import XCTest
import Combine
import CombineExpectations
@testable import Metatext

class AuthenticationServiceTests: XCTestCase {
    func testAddIdentity() throws {
        let environment = AppEnvironment.fresh()
        let sut = AuthenticationService(environment: environment)
        let instanceURL = URL(string: "https://mastodon.social")!
        let addedIDRecorder = sut.authenticate(instanceURL: instanceURL).record()

        let addedIdentityID = try wait(for: addedIDRecorder.next(), timeout: 1)
        let identityRecorder = environment.identityDatabase.identityObservation(id: addedIdentityID).record()
        let addedIdentity = try wait(for: identityRecorder.next(), timeout: 1)

        XCTAssertEqual(addedIdentity.id, addedIdentityID)
        XCTAssertEqual(addedIdentity.url, URL(string: "https://mastodon.social")!)

        let secretsService = SecretsService(identityID: addedIdentity.id, keychainService: environment.keychainService)

        XCTAssertEqual(
            try secretsService.item(.clientID) as String?, "AUTHORIZATION_CLIENT_ID_STUB_VALUE")
        XCTAssertEqual(
            try secretsService.item(.clientSecret) as String?, "AUTHORIZATION_CLIENT_SECRET_STUB_VALUE")
        XCTAssertEqual(
            try secretsService.item(.accessToken) as String?, "ACCESS_TOKEN_STUB_VALUE")
    }
}
