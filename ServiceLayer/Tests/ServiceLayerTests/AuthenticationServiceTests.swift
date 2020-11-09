// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import CombineExpectations
@testable import ServiceLayer
@testable import ServiceLayerMocks
import XCTest

final class AuthenticationServiceTests: XCTestCase {
    func testAuthentication() throws {
        let sut = AuthenticationService(url: URL(string: "https://mastodon.social")!, environment: .mock())
        let authenticationRecorder = sut.authenticate().record()
        let (appAuthorization, accessToken) = try wait(for: authenticationRecorder.next(), timeout: 1)

        XCTAssertEqual(appAuthorization.clientId, "AUTHORIZATION_CLIENT_ID_STUB_VALUE")
        XCTAssertEqual(appAuthorization.clientSecret, "AUTHORIZATION_CLIENT_SECRET_STUB_VALUE")
        XCTAssertEqual(accessToken.accessToken, "ACCESS_TOKEN_STUB_VALUE")
    }
}
