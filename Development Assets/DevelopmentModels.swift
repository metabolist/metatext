// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

// swiftlint:disable force_try
private let decoder = MastodonDecoder()
private var cancellables = Set<AnyCancellable>()
private let devInstanceURL = URL(string: "https://mastodon.social")!
private let devIdentityID = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
private let devAccessToken = "DEVELOPMENT_ACCESS_TOKEN"

extension Secrets {
    static func fresh() -> Secrets { Secrets(keychain: FakeKeychain()) }

    static let development: Secrets = {
        let secrets = Secrets.fresh()

        try! secrets.set("DEVELOPMENT_CLIENT_ID", forItem: .clientID, forIdentityID: devIdentityID)
        try! secrets.set("DEVELOPMENT_CLIENT_SECRET", forItem: .clientSecret, forIdentityID: devIdentityID)
        try! secrets.set(devAccessToken, forItem: .accessToken, forIdentityID: devIdentityID)

        return secrets
    }()
}

extension Defaults {
    static func fresh() -> Defaults { Defaults(userDefaults: FakeUserDefaults()) }

    static let development: Defaults = {
        let preferences = Defaults.fresh()

        // Do future setup here

        return preferences
    }()
}

extension Account {
    static let development = try! decoder.decode(Account.self, from: Data(officialAccountJSON.utf8))
}

extension Instance {
    static let development = try! decoder.decode(Instance.self, from: Data(officialInstanceJSON.utf8))
}

extension IdentityDatabase {
    static func fresh() -> IdentityDatabase { try! IdentityDatabase(inMemory: true) }

    static var development: IdentityDatabase = {
        let db = IdentityDatabase.fresh()

        db.createIdentity(id: devIdentityID, url: devInstanceURL)
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

extension AppEnvironment {
    static func fresh(
        URLSessionConfiguration: URLSessionConfiguration = .stubbing,
        identityDatabase: IdentityDatabase = .fresh(),
        defaults: Defaults = .fresh(),
        secrets: Secrets = .fresh(),
        webAuthSessionType: WebAuthSession.Type = SuccessfulStubbingWebAuthSession.self) -> AppEnvironment {
        AppEnvironment(
            URLSessionConfiguration: URLSessionConfiguration,
            identityDatabase: identityDatabase,
            defaults: defaults,
            secrets: secrets,
            webAuthSessionType: webAuthSessionType)
    }

    static let development = AppEnvironment(
        URLSessionConfiguration: .stubbing,
        identityDatabase: .development,
        defaults: .development,
        secrets: .development,
        webAuthSessionType: SuccessfulStubbingWebAuthSession.self)
}

extension IdentityService {
    static let development = try! IdentityService(identityID: devIdentityID, appEnvironment: .development)
}

extension RootViewModel {
    static let development = RootViewModel(environment: .development)
}

extension MainNavigationViewModel {
    static let development = RootViewModel.development.mainNavigationViewModel(identityID: devIdentityID)!
}

#if os(iOS)
extension SecondaryNavigationViewModel {
    static let development = MainNavigationViewModel.development.secondaryNavigationViewModel()
}

extension IdentitiesViewModel {
    static let development = IdentitiesViewModel(identityService: .development)
}
#endif

extension PreferencesViewModel {
    static let development = PreferencesViewModel(identityService: .development)
}

extension PostingReadingPreferencesViewModel {
    static let development = PostingReadingPreferencesViewModel(identityService: .development)
}

// swiftlint:enable force_try
