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
            identityDatabase: identityDatabase,
            preferences: Preferences(userDefaults: .standard),
            secrets: Secrets(keychain: Keychain(service: "com.metabolist.metatext")),
            webAuthSessionType: RealWebAuthSession.self)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(
                    SceneViewModel(
                        networkClient: MastodonClient(),
                        environment: environment))
        }
    }
}
