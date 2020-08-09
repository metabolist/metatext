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
            secrets: Secrets(keychainService: KeychainService(serviceName: "com.metabolist.metatext")),
            webAuthSessionType: WebAuthSession.self)
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: RootViewModel(environment: environment))
        }
    }
}
