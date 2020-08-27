// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

@main
struct MetatextApp: App {
    // swiftlint:disable weak_delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    // swiftlint:enable weak_delegate

    private let allIdentitiesService: AllIdentitiesService = {
        let identityDatabase: IdentityDatabase

        do {
            try identityDatabase = IdentityDatabase()
        } catch {
            fatalError("Failed to initialize identity database")
        }

        return AllIdentitiesService(identityDatabase: identityDatabase, environment: .live)
    }()

    var body: some Scene {
        WindowGroup {
            RootView(
                viewModel: RootViewModel(appDelegate: appDelegate,
                                         allIdentitiesService: allIdentitiesService,
                                         userNotificationService: UserNotificationService()))
        }
    }
}
