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
        let recorder = sut.addedIdentity.record()

        sut.urlFieldText = "https://mastodon.social"
        sut.goTapped()

        let addedIdentity = try wait(for: recorder.next(), timeout: 1)

        XCTAssertEqual(try identityDatabase.identity(id: addedIdentity.id), addedIdentity)
        XCTAssertEqual(addedIdentity.url, URL(string: "https://mastodon.social")!)
        XCTAssertEqual(
            try secrets.item(.clientID, forIdentityID: addedIdentity.id) as String?,
            "AUTHORIZATION_CLIENT_ID_STUB_VALUE")
        XCTAssertEqual(
            try secrets.item(.clientSecret, forIdentityID: addedIdentity.id) as String?,
            "AUTHORIZATION_CLIENT_SECRET_STUB_VALUE")
        XCTAssertEqual(
            try secrets.item(.accessToken, forIdentityID: addedIdentity.id) as String?,
            "ACCESS_TOKEN_STUB_VALUE")
    }

    func testAddIdentityWithoutScheme() throws {
        let sut = AddIdentityViewModel(
            networkClient: networkClient,
            identityDatabase: identityDatabase,
            secrets: secrets,
            webAuthenticationSessionType: SuccessfulStubbingWebAuthenticationSession.self)
        let recorder = sut.addedIdentity.record()

        sut.urlFieldText = "mastodon.social"
        sut.goTapped()

        let addedIdentity = try wait(for: recorder.next(), timeout: 1)

        XCTAssertEqual(try identityDatabase.identity(id: addedIdentity.id), addedIdentity)
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
