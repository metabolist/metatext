// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct StartupAndSyncingPreferencesView: View {
    @EnvironmentObject var identification: Identification

    var body: some View {
        Form {
            Section(header: Text("preferences.startup-and-syncing.home-timeline")) {
                Picker("preferences.startup-and-syncing.position-on-startup",
                       selection: $identification.appPreferences.homeTimelineBehavior) {
                    ForEach(AppPreferences.PositionBehavior.allCases) { option in
                        Text(option.localizedStringKey).tag(option)
                    }
                }
            }
            Section(header: Text("preferences.startup-and-syncing.notifications-tab")) {
                Picker("preferences.startup-and-syncing.position-on-startup",
                       selection: $identification.appPreferences.notificationsTabBehavior) {
                    ForEach(AppPreferences.PositionBehavior.allCases) { option in
                        Text(option.localizedStringKey).tag(option)
                    }
                }
            }
        }
    }
}

extension AppPreferences.PositionBehavior {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .rememberPosition:
            return "preferences.startup-and-syncing.remember-position"
        case .syncPosition:
            return "preferences.startup-and-syncing.sync-position"
        case .newest:
            return "preferences.startup-and-syncing.newest"
        }
    }
}

#if DEBUG
import PreviewViewModels

struct StartupAndSyncingPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        StartupAndSyncingPreferencesView()
            .environmentObject(Identification.preview)
    }
}
#endif
