// Copyright © 2020 Metabolist. All rights reserved.

import XCTest
import Combine
import CombineExpectations
@testable import ServiceLayer
@testable import ServiceLayerMocks

class AuthenticationServiceTests: XCTestCase {
    func testAuthentication() throws {
        let sut = AuthenticationService(environment: .mock())
        let instanceURL = URL(string: "https://mastodon.social")!
        let appAuthorizationRecorder = sut.authorizeApp(instanceURL: instanceURL).record()
        let appAuthorization = try wait(for: appAuthorizationRecorder.next(), timeout: 1)

        XCTAssertEqual(appAuthorization.clientId, "AUTHORIZATION_CLIENT_ID_STUB_VALUE")
        XCTAssertEqual(appAuthorization.clientSecret, "AUTHORIZATION_CLIENT_SECRET_STUB_VALUE")

        let accessTokenRecorder = sut.authenticate(
            instanceURL: instanceURL,
            appAuthorization: appAuthorization)
            .record()
        let accessToken = try wait(for: accessTokenRecorder.next(), timeout: 1)

        XCTAssertEqual(accessToken.accessToken, "ACCESS_TOKEN_STUB_VALUE")
    }
}
