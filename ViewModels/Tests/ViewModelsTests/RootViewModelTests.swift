// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import CombineExpectations
import ServiceLayer
import ServiceLayerMocks
@testable import ViewModels
import XCTest

class RootViewModelTests: XCTestCase {
    var cancellables = Set<AnyCancellable>()

    func testAddIdentity() throws {
        let sut = try RootViewModel(
            environment: .mock(),
            registerForRemoteNotifications: { Empty().setFailureType(to: Error.self).eraseToAnyPublisher() })
        let recorder = sut.$identification.record()

        XCTAssertNil(try wait(for: recorder.next(), timeout: 1))

        let addIdentityViewModel = sut.addIdentityViewModel()

        addIdentityViewModel.addedIdentityID
            .sink(receiveValue: sut.identitySelected(id:))
            .store(in: &cancellables)

        addIdentityViewModel.urlFieldText = "https://mastodon.social"
        addIdentityViewModel.logInTapped()

        let mainNavigationViewModel = try wait(for: recorder.next(), timeout: 1)!

        XCTAssertNotNil(mainNavigationViewModel)
    }
}
