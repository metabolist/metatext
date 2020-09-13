// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPIStubs
import MockKeychain
import Secrets
import ServiceLayer
import ServiceLayerMocks
import ViewModels

// swiftlint:disable force_try

let db: IdentityDatabase = {
    let id = UUID()
    let db = try! IdentityDatabase(inMemory: true, keychain: MockKeychain.self)
    let secrets = Secrets(identityID: id, keychain: MockKeychain.self)

    try! secrets.setInstanceURL(.previewInstanceURL)
    try! secrets.setAccessToken(UUID().uuidString)

    _ = db.createIdentity(id: id, url: .previewInstanceURL, authenticated: true, pending: false)
            .receive(on: ImmediateScheduler.shared)
            .sink { _ in } receiveValue: { _ in }

    _ = db.updateInstance(.preview, forIdentityID: id)
        .receive(on: ImmediateScheduler.shared)
        .sink { _ in } receiveValue: { _ in }

    _ = db.updateAccount(.preview, forIdentityID: id)
        .receive(on: ImmediateScheduler.shared)
        .sink { _ in } receiveValue: { _ in }

    return db
}()

let environment = AppEnvironment.mock(fixtureDatabase: db)
let decoder = MastodonDecoder()

public extension URL {
    static let previewInstanceURL = URL(string: "https://mastodon.social")!
}

public extension Account {
    static let preview = try! decoder.decode(Account.self, from: StubData.account)
}

public extension Instance {
    static let preview = try! decoder.decode(Instance.self, from: StubData.instance)
}

public extension RootViewModel {
    static let preview = try! RootViewModel(environment: environment) { Empty().eraseToAnyPublisher() }
}

public extension Identification {
    static let preview = RootViewModel.preview.navigationViewModel!.identification
}

// swiftlint:enable force_try
