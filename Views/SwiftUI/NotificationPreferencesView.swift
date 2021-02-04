// Copyright © 2021 Metabolist. All rights reserved.

import Mastodon
import SwiftUI
import ViewModels

struct NotificationPreferencesView: View {
    @StateObject var viewModel: PreferencesViewModel
    @StateObject var identityContext: IdentityContext

    init(viewModel: PreferencesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _identityContext = StateObject(wrappedValue: viewModel.identityContext)
    }

    var body: some View {
        Form {
            Section {
                Toggle("preferences.notifications.include-pictures",
                       isOn: $identityContext.appPreferences.notificationPictures)
                Toggle("preferences.notifications.include-account-name",
                       isOn: $identityContext.appPreferences.notificationAccountName)
            }
            Section(header: Text("preferences.notifications.sounds")) {
                ForEach(MastodonNotification.NotificationType.allCasesExceptUnknown) { type in
                    Toggle(type.localizedStringKey, isOn: .init {
                        viewModel.identityContext.appPreferences.notificationSounds.contains(type)
                    } set: {
                        if $0 {
                            viewModel.identityContext.appPreferences.notificationSounds.insert(type)
                        } else {
                            viewModel.identityContext.appPreferences.notificationSounds.remove(type)
                        }
                    })
                }
            }
        }
        .navigationTitle("preferences.notifications")
    }
}

extension MastodonNotification.NotificationType {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .follow:
            return "preferences.notification-types.follow"
        case .mention:
            return "preferences.notification-types.mention"
        case .reblog:
            return "preferences.notification-types.reblog"
        case .favourite:
            return "preferences.notification-types.favourite"
        case .poll:
            return "preferences.notification-types.poll"
        case .followRequest:
            return "preferences.notification-types.follow-request"
        case .status:
            return "preferences.notification-types.status"
        case .unknown:
            return ""
        }
    }
}

#if DEBUG
import PreviewViewModels

struct NotificationPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPreferencesView(viewModel: .init(identityContext: .preview))
    }
}
#endif
