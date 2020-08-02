// Copyright © 2020 Metabolist. All rights reserved.

import XCTest
import Combine
import CombineExpectations
@testable import Metatext

class AddIdentityViewModelTests: XCTestCase {
    var networkClient: MastodonClient!
    var identityDatabase: IdentityDatabase!
    var secrets: Secrets!
    var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        networkClient = MastodonClient(configuration: .stubbing)
        identityDatabase = try IdentityDatabase(inMemory: true)
        secrets = Secrets(keychain: FakeKeychain())
    }

    func testAddIdentity() throws {
        let sut = AddIdentityViewModel(
            networkClient: networkClient,
            identityDatabase: identityDatabase,
            secrets: secrets,
            webAuthenticationSessionType: SuccessfulStubbingWebAuthenticationSession.self)
        let addedIDRecorder = sut.$addedIdentityID.record()
        _ = try wait(for: addedIDRecorder.next(), timeout: 1)

        sut.urlFieldText = "https://mastodon.social"
        sut.goTapped()

        let addedIdentityID = try wait(for: addedIDRecorder.next(), timeout: 1)!
        let identityRecorder = identityDatabase.identityObservation(id: addedIdentityID).record()
        let addedIdentity = try wait(for: identityRecorder.next(), timeout: 1)!

        XCTAssertEqual(addedIdentity.id, addedIdentityID)
        XCTAssertEqual(addedIdentity.url, URL(string: "https://mastodon.social")!)
        XCTAssertEqual(
            try secrets.item(.clientID, forIdentityID: addedIdentityID) as String?,
            "AUTHORIZATION_CLIENT_ID_STUB_VALUE")
        XCTAssertEqual(
            try secrets.item(.clientSecret, forIdentityID: addedIdentityID) as String?,
            "AUTHORIZATION_CLIENT_SECRET_STUB_VALUE")
        XCTAssertEqual(
            try secrets.item(.accessToken, forIdentityID: addedIdentityID) as String?,
            "ACCESS_TOKEN_STUB_VALUE")
    }

    func testAddIdentityWithoutScheme() throws {
        let sut = AddIdentityViewModel(
            networkClient: networkClient,
            identityDatabase: identityDatabase,
            secrets: secrets,
            webAuthenticationSessionType: SuccessfulStubbingWebAuthenticationSession.self)
        let addedIDRecorder = sut.$addedIdentityID.record()
        _ = try wait(for: addedIDRecorder.next(), timeout: 1)

        sut.urlFieldText = "mastodon.social"
        sut.goTapped()

        let addedIdentityID = try wait(for: addedIDRecorder.next(), timeout: 1)!
        let identityRecorder = identityDatabase.identityObservation(id: addedIdentityID).record()
        let addedIdentity = try wait(for: identityRecorder.next(), timeout: 1)!

        XCTAssertEqual(addedIdentity.url, URL(string: "https://mastodon.social")!)
    }

    func testInvalidURL() throws {
        let sut = AddIdentityViewModel(
            networkClient: networkClient,
            identityDatabase: identityDatabase,
            secrets: secrets,
            webAuthenticationSessionType: SuccessfulStubbingWebAuthenticationSession.self)
        let recorder = sut.$alertItem.dropFirst().record()

        sut.urlFieldText = "🐘.social"
        sut.goTapped()

        let alertItem = try wait(for: recorder.next(), timeout: 1)

        XCTAssertEqual((alertItem?.error as? URLError)?.code, URLError.badURL)
    }
}
