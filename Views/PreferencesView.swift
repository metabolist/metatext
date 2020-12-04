// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct PreferencesView: View {
    @StateObject var viewModel: PreferencesViewModel
    @EnvironmentObject var identification: Identification

    var body: some View {
        Form {
            Section(header: Text(viewModel.handle)) {
                NavigationLink("preferences.posting-reading",
                               destination: PostingReadingPreferencesView(
                                viewModel: .init(identification: identification)))
                NavigationLink("preferences.filters",
                               destination: FiltersView(
                                viewModel: .init(identification: identification)))
                if viewModel.shouldShowNotificationTypePreferences {
                    NavigationLink("preferences.notification-types",
                                   destination: NotificationTypesPreferencesView(
                                    viewModel: .init(identification: identification)))
                }
                NavigationLink("preferences.muted-users",
                               destination: TableView(viewModelClosure: viewModel.mutedUsersViewModel)
                                .navigationTitle(Text("preferences.muted-users")))
                NavigationLink("preferences.blocked-users",
                               destination: TableView(viewModelClosure: viewModel.blockedUsersViewModel)
                                .navigationTitle(Text("preferences.blocked-users")))
                NavigationLink("preferences.blocked-domains",
                               destination: DomainBlocksView(viewModel: viewModel.domainBlocksViewModel()))
            }
            Section(header: Text("preferences.app")) {
                NavigationLink("preferences.media",
                               destination: MediaPreferencesView(
                                viewModel: .init(identification: identification)))
                NavigationLink("preferences.startup-and-syncing",
                               destination: StartupAndSyncingPreferencesView())
            }
        }
        .navigationTitle("preferences")
    }
}

#if DEBUG
import PreviewViewModels

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(viewModel: .init(identification: .preview))
    }
}
#endif
