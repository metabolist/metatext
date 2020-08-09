// Copyright © 2020 Metabolist. All rights reserved.

import XCTest
import Combine
import CombineExpectations
@testable import Metatext

class RootViewModelTests: XCTestCase {
    var cancellables = Set<AnyCancellable>()

    func testAddIdentity() throws {
        let environment = AppEnvironment.fresh()
        let sut = RootViewModel(
            identitiesService: IdentitiesService(environment: environment))
        let recorder = sut.$mainNavigationViewModel.record()

        XCTAssertNil(try wait(for: recorder.next(), timeout: 1))

        let addIdentityViewModel = sut.addIdentityViewModel()

        addIdentityViewModel.addedIdentityID
            .sink(receiveValue: sut.newIdentitySelected(id:))
            .store(in: &cancellables)

        addIdentityViewModel.urlFieldText = "https://mastodon.social"
        addIdentityViewModel.goTapped()

        let mainNavigationViewModel = try wait(for: recorder.next(), timeout: 1)!

        XCTAssertNotNil(mainNavigationViewModel)
    }
}
