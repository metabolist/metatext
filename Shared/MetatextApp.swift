// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

@main
struct MetatextApp: App {
    // swiftlint:disable weak_delegate
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #else
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif
    // swiftlint:enable weak_delegate

    private let identitiesService: IdentitiesService = {
        let identityDatabase: IdentityDatabase

        do {
            try identityDatabase = IdentityDatabase()
        } catch {
            fatalError("Failed to initialize identity database")
        }

        return IdentitiesService(identityDatabase: identityDatabase, environment: .live)
    }()

    var body: some Scene {
        WindowGroup {
            RootView(
                viewModel: RootViewModel(appDelegate: appDelegate,
                                         identitiesService: identitiesService,
                                         userNotificationService: UserNotificationService()))
        }
    }
}
