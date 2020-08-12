// Copyright © 2020 Metabolist. All rights reserved.

import XCTest
import Combine
import CombineExpectations
@testable import Metatext

class RootViewModelTests: XCTestCase {
    var cancellables = Set<AnyCancellable>()

    func testAddIdentity() throws {
        let sut = RootViewModel(appDelegate: AppDelegate(),
                                identitiesService: IdentitiesService(
                                    identityDatabase: .fresh(),
                                    environment: .development),
                                notificationService: NotificationService())
        let recorder = sut.$mainNavigationViewModel.record()

        XCTAssertNil(try wait(for: recorder.next(), timeout: 1))

        let addIdentityViewModel = sut.addIdentityViewModel()

        addIdentityViewModel.addedIdentityIDAndURL
            .sink(receiveValue: sut.newIdentityCreated(id:instanceURL:))
            .store(in: &cancellables)

        addIdentityViewModel.urlFieldText = "https://mastodon.social"
        addIdentityViewModel.logInTapped()

        let mainNavigationViewModel = try wait(for: recorder.next(), timeout: 1)!

        XCTAssertNotNil(mainNavigationViewModel)
    }
}
