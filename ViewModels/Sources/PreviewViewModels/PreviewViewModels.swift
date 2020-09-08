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
    let url = URL(string: "https://mastodon.social")!
    let db = try! IdentityDatabase(inMemory: true, keychain: MockKeychain.self)
    let decoder = MastodonDecoder()
    let instance = try! decoder.decode(Instance.self, from: StubData.instance)
    let account = try! decoder.decode(Account.self, from: StubData.account)
    let secrets = Secrets(identityID: id, keychain: MockKeychain.self)

    try! secrets.setInstanceURL(url)
    try! secrets.setAccessToken(UUID().uuidString)

    _ = db.createIdentity(id: id, url: url)
            .receive(on: ImmediateScheduler.shared)
            .sink { _ in } receiveValue: { _ in }

    _ = db.updateInstance(instance, forIdentityID: id)
        .receive(on: ImmediateScheduler.shared)
        .sink { _ in } receiveValue: { _ in }

    _ = db.updateAccount(account, forIdentityID: id)
        .receive(on: ImmediateScheduler.shared)
        .sink { _ in } receiveValue: { _ in }

    return db
}()

let environment = AppEnvironment.mock(fixtureDatabase: db)

public extension RootViewModel {
    static let preview = try! RootViewModel(environment: environment) { Empty().eraseToAnyPublisher() }
}

public extension Identification {
    static let preview = RootViewModel.preview.identification!
}

// swiftlint:enable force_try
