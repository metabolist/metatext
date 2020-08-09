// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

@main
struct MetatextApp: App {
    private let environment: AppEnvironment

    init() {
        let identityDatabase: IdentityDatabase

        do {
            try identityDatabase = IdentityDatabase()
        } catch {
            fatalError("Failed to initialize identity database")
        }

        environment = AppEnvironment(
            URLSessionConfiguration: .default,
            identityDatabase: identityDatabase,
            defaults: Defaults(userDefaults: .standard),
            keychainService: KeychainService(serviceName: Self.keychainServiceName),
            webAuthSessionType: WebAuthSession.self)
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: RootViewModel(identitiesService: IdentitiesService(environment: environment)))
        }
    }
}

private extension MetatextApp {
    static let keychainServiceName = "com.metabolist.metatext"
}
