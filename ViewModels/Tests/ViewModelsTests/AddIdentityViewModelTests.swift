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

final class AddIdentityViewModelTests: XCTestCase {
    func testAddIdentity() throws {
        let uuid = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        let environment = AppEnvironment.mock(uuid: { uuid })
        let allIdentitiesService = try AllIdentitiesService(environment: environment)
        let sut = AddIdentityViewModel(
            allIdentitiesService: allIdentitiesService,
            instanceURLService: InstanceURLService(environment: environment))
        let addedIdRecorder = allIdentitiesService.identitiesCreated.record()

        sut.urlFieldText = "https://mastodon.social"
        sut.logInTapped()

        _ = try wait(for: addedIdRecorder.next(), timeout: 1)
    }

    func testAddIdentityWithoutScheme() throws {
        let uuid = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        let environment = AppEnvironment.mock(uuid: { uuid })
        let allIdentitiesService = try AllIdentitiesService(environment: environment)
        let sut = AddIdentityViewModel(
            allIdentitiesService: allIdentitiesService,
            instanceURLService: InstanceURLService(environment: environment))
        let addedIdRecorder = allIdentitiesService.identitiesCreated.record()

        sut.urlFieldText = "mastodon.social"
        sut.logInTapped()

        _ = try wait(for: addedIdRecorder.next(), timeout: 1)
    }

    func testInvalidURL() throws {
        let environment = AppEnvironment.mock()
        let sut = AddIdentityViewModel(
            allIdentitiesService: try AllIdentitiesService(environment: environment),
            instanceURLService: InstanceURLService(environment: environment))
        let recorder = sut.$alertItem.record()

        XCTAssertNil(try wait(for: recorder.next(), timeout: 1))

        sut.urlFieldText = "🐘.social"
        sut.logInTapped()

        let alertItem = try wait(for: recorder.next(), timeout: 1)

        XCTAssertEqual((alertItem?.error as? AddIdentityError), AddIdentityError.unableToConnectToInstance)
    }

    func testDoesNotAlertCanceledLogin() throws {
        let environment = AppEnvironment.mock(webAuthSessionType: CanceledLoginMockWebAuthSession.self)
        let sut = AddIdentityViewModel(
            allIdentitiesService: try AllIdentitiesService(environment: environment),
            instanceURLService: InstanceURLService(environment: environment))
        let recorder = sut.$alertItem.record()

        XCTAssertNil(try wait(for: recorder.next(), timeout: 1))

        sut.urlFieldText = "https://mastodon.social"
        sut.logInTapped()

        try wait(for: recorder.next().inverted, timeout: 1)
    }
}
