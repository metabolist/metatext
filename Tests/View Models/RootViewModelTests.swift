// Copyright © 2020 Metabolist. All rights reserved.

import XCTest
import Combine
import CombineExpectations
@testable import Metatext

class RootViewModelTests: XCTestCase {
    func testAddIdentity() throws {
        let sut = RootViewModel(environment: .fresh())
        let identityIDRecorder = sut.$identityID.record()

        XCTAssertNil(try wait(for: identityIDRecorder.next(), timeout: 1))

        let addIdentityViewModel = sut.addIdentityViewModel()

        addIdentityViewModel.urlFieldText = "https://mastodon.social"
        addIdentityViewModel.goTapped()

        let identityID = try wait(for: identityIDRecorder.next(), timeout: 1)!

        XCTAssertNotNil(identityID)
    }
}
