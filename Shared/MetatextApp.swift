// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

@main
struct MetatextApp: App {
    private let identityDatabase: IdentityDatabase
    private let keychainServive = KeychainService(serviceName: "com.metabolist.metatext")
    private let environment = AppEnvironment(
        URLSessionConfiguration: .default,
        webAuthSessionType: WebAuthSession.self)

    init() {
        do {
            try identityDatabase = IdentityDatabase()
        } catch {
            fatalError("Failed to initialize identity database")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                viewModel: RootViewModel(identitiesService: IdentitiesService(
                                            identityDatabase: identityDatabase,
                                            keychainService: keychainServive,
                                            environment: environment)))
        }
    }
}

private extension MetatextApp {
    static let keychainServiceName = "com.metabolist.metatext"
}
