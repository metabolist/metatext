// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

@main
struct MetatextApp: App {
    private let identityDatabase: IdentityDatabase
    private let secrets = Secrets(keychain: Keychain(service: "com.metabolist.metatext"))

    init() {
        do {
            try identityDatabase = IdentityDatabase()
        } catch {
            fatalError("Failed to initialize identity database")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(
                    SceneViewModel(
                        networkClient: MastodonClient(),
                        identityDatabase: identityDatabase,
                        secrets: secrets))
        }
    }
}
