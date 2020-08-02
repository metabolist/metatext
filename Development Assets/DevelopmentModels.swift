// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

// swiftlint:disable force_try
private let decoder = MastodonDecoder()
private var cancellables = Set<AnyCancellable>()
private let devIdentityID = "DEVELOPMENT_IDENTITY_ID"

extension Secrets {
    static let development: Secrets = {
        let secrets = Secrets(keychain: FakeKeychain())

        try! secrets.set("DEVELOPMENT_CLIENT_ID", forItem: .clientID, forIdentityID: devIdentityID)
        try! secrets.set("DEVELOPMENT_CLIENT_SECRET", forItem: .clientSecret, forIdentityID: devIdentityID)
        try! secrets.set("DEVELOPMENT_ACCESS_TOKEN", forItem: .accessToken, forIdentityID: devIdentityID)

        return secrets
    }()
}

extension MastodonClient {
    static let development = MastodonClient(configuration: .stubbing)
}

extension Account {
    static let development = try! decoder.decode(Account.self, from: Data(officialAccountJSON.utf8))
}

extension Instance {
    static let development = try! decoder.decode(Instance.self, from: Data(officialInstanceJSON.utf8))
}

extension IdentityDatabase {
    static var development: IdentityDatabase = {
        let db = try! IdentityDatabase(inMemory: true)

        db.createIdentity(id: devIdentityID, url: URL(string: "https://mastodon.social")!)
            .receive(on: ImmediateScheduler.shared)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)

        db.updateAccount(.development, forIdentityID: devIdentityID)
            .receive(on: ImmediateScheduler.shared)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)

        db.updateInstance(.development, forIdentityID: devIdentityID)
            .receive(on: ImmediateScheduler.shared)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)

        return db
    }()
}

extension Identity {
    static let development: Identity = {
        var identity: Identity?

        IdentityDatabase.development.identityObservation(id: devIdentityID)
            .assertNoFailure()
            .sink(receiveValue: { identity = $0 })
            .store(in: &cancellables)

        return identity!
    }()
}

extension SceneViewModel {
    static let development = SceneViewModel(
        networkClient: .development,
        identityDatabase: .development,
        secrets: .development)
}

// swiftlint:enable force_try
