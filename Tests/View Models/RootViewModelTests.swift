// Copyright © 2020 Metabolist. All rights reserved.

import XCTest
import Combine
import CombineExpectations
@testable import Metatext

class RootViewModelTests: XCTestCase {
    func testAddIdentity() throws {
        let sut = RootViewModel(environment: .fresh())
        let recorder = sut.$mainNavigationViewModel.record()

        XCTAssertNil(try wait(for: recorder.next(), timeout: 1))

        let addIdentityViewModel = sut.addIdentityViewModel()

        addIdentityViewModel.urlFieldText = "https://mastodon.social"
        addIdentityViewModel.goTapped()

        let mainNavigationViewModel = try wait(for: recorder.next(), timeout: 1)!

        XCTAssertNotNil(mainNavigationViewModel)
    }
}
