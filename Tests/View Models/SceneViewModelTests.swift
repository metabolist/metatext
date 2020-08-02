// Copyright © 2020 Metabolist. All rights reserved.

import XCTest
import Combine
import CombineExpectations
@testable import Metatext

class SceneViewModelTests: XCTestCase {
    func testAddIdentity() throws {
        let sut = SceneViewModel(networkClient: .fresh(), environment: .fresh())
        let identityRecorder = sut.$identity.record()

        XCTAssertNil(try wait(for: identityRecorder.next(), timeout: 1))

        let addIdentityViewModel = sut.addIdentityViewModel()

        addIdentityViewModel.urlFieldText = "https://mastodon.social"
        addIdentityViewModel.goTapped()

        let identity = try wait(for: identityRecorder.next(), timeout: 1)!

        XCTAssertEqual(identity.id, addIdentityViewModel.addedIdentityID)
    }
}
