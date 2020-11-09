// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import CombineExpectations
import ServiceLayer
import ServiceLayerMocks
@testable import ViewModels
import XCTest

final class RootViewModelTests: XCTestCase {
    var cancellables = Set<AnyCancellable>()

    func testAddIdentity() throws {
        let uuid = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        let sut = try RootViewModel(
            environment: .mock(uuid: { uuid }),
            registerForRemoteNotifications: { Empty().setFailureType(to: Error.self).eraseToAnyPublisher() })
        let recorder = sut.$navigationViewModel.record()

        XCTAssertNil(try wait(for: recorder.next(), timeout: 1))

        let addIdentityViewModel = sut.addIdentityViewModel()

        addIdentityViewModel.urlFieldText = "https://mastodon.social"
        addIdentityViewModel.logInTapped()

        let navigationViewModel = try wait(for: recorder.next(), timeout: 1)!

        XCTAssertNotNil(navigationViewModel)
    }
}
