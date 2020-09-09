// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import CombineExpectations
import HTTP
import Mastodon
import MockKeychain
import ServiceLayer
import ServiceLayerMocks
@testable import ViewModels
import XCTest

class AddIdentityViewModelTests: XCTestCase {
    func testAddIdentity() throws {
        let environment = AppEnvironment.mock()
        let sut = AddIdentityViewModel(
            allIdentitiesService: try AllIdentitiesService(environment: environment),
            instanceFilterService: InstanceFilterService(environment: environment))
        let addedIDRecorder = sut.addedIdentityID.record()

        sut.urlFieldText = "https://mastodon.social"
        sut.logInTapped()

        _ = try wait(for: addedIDRecorder.next(), timeout: 1)
    }

    func testAddIdentityWithoutScheme() throws {
        let environment = AppEnvironment.mock()
        let sut = AddIdentityViewModel(
            allIdentitiesService: try AllIdentitiesService(environment: environment),
            instanceFilterService: InstanceFilterService(environment: environment))
        let addedIDRecorder = sut.addedIdentityID.record()

        sut.urlFieldText = "mastodon.social"
        sut.logInTapped()

        _ = try wait(for: addedIDRecorder.next(), timeout: 1)
    }

    func testInvalidURL() throws {
        let environment = AppEnvironment.mock()
        let sut = AddIdentityViewModel(
            allIdentitiesService: try AllIdentitiesService(environment: environment),
            instanceFilterService: InstanceFilterService(environment: environment))
        let recorder = sut.$alertItem.record()

        XCTAssertNil(try wait(for: recorder.next(), timeout: 1))

        sut.urlFieldText = "🐘.social"
        sut.logInTapped()

        let alertItem = try wait(for: recorder.next(), timeout: 1)

        XCTAssertEqual((alertItem?.error as? URLError)?.code, URLError.badURL)
    }

    func testDoesNotAlertCanceledLogin() throws {
        let environment = AppEnvironment.mock(webAuthSessionType: CanceledLoginMockWebAuthSession.self)
        let sut = AddIdentityViewModel(
            allIdentitiesService: try AllIdentitiesService(environment: environment),
            instanceFilterService: InstanceFilterService(environment: environment))
        let recorder = sut.$alertItem.record()

        XCTAssertNil(try wait(for: recorder.next(), timeout: 1))

        sut.urlFieldText = "https://mastodon.social"
        sut.logInTapped()

        try wait(for: recorder.next().inverted, timeout: 1)
    }
}
