// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI
import MastodonAPIStubs
import MockKeychain
import Secrets
import ServiceLayer
import ServiceLayerMocks
import ViewModels

// swiftlint:disable force_try

let identityId = Identity.Id()

let db: IdentityDatabase = {
    let db = try! IdentityDatabase(inMemory: true, appGroup: "", keychain: MockKeychain.self)
    let secrets = Secrets(identityId: identityId, keychain: MockKeychain.self)

    try! secrets.setInstanceURL(.previewInstanceURL)
    try! secrets.setAccessToken(UUID().uuidString)

    _ = db.createIdentity(id: identityId, url: .previewInstanceURL, authenticated: true, pending: false)
            .receive(on: ImmediateScheduler.shared)
            .sink { _ in } receiveValue: { _ in }

    _ = db.updateInstance(.preview, id: identityId)
        .receive(on: ImmediateScheduler.shared)
        .sink { _ in } receiveValue: { _ in }

    _ = db.updateAccount(.preview, id: identityId)
        .receive(on: ImmediateScheduler.shared)
        .sink { _ in } receiveValue: { _ in }

    return db
}()

let environment = AppEnvironment.mock(fixtureDatabase: db)
let decoder = MastodonDecoder()

extension MastodonAPIClient {
    static let preview = MastodonAPIClient(
        session: URLSession(configuration: .stubbing),
        instanceURL: .previewInstanceURL)
}

extension ContentDatabase {
    static let preview = try! ContentDatabase(
        id: identityId,
        useHomeTimelineLastReadId: false,
        inMemory: true,
        appGroup: "group.metabolist.metatext",
        keychain: MockKeychain.self)
}

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
    static let preview = try! RootViewModel(environment: environment,
                                            registerForRemoteNotifications: { Empty().eraseToAnyPublisher() })
}

public extension IdentityContext {
    static let preview = RootViewModel.preview.navigationViewModel!.identityContext
}

public extension ReportViewModel {
    static let preview = ReportViewModel(
        accountService: AccountService(
            account: .preview,
            environment: environment,
            mastodonAPIClient: .preview,
            contentDatabase: .preview),
        identityContext: .preview)
}

public extension MuteViewModel {
    static let preview = MuteViewModel(
        accountService: AccountService(
            account: .preview,
            environment: environment,
            mastodonAPIClient: .preview,
            contentDatabase: .preview),
        identityContext: .preview)
}

public extension DomainBlocksViewModel {
    static let preview = DomainBlocksViewModel(service: .init(mastodonAPIClient: .preview))
}

// swiftlint:enable force_try
