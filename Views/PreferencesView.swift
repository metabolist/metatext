// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct PreferencesView: View {
    @StateObject var viewModel: PreferencesViewModel

    var body: some View {
        Form {
            Section(header: Text(viewModel.handle)) {
                NavigationLink("preferences.posting-reading",
                               destination: PostingReadingPreferencesView(
                                viewModel: .init(identityContext: viewModel.identityContext)))
                NavigationLink("preferences.filters",
                               destination: FiltersView(
                                viewModel: .init(identityContext: viewModel.identityContext)))
                if viewModel.shouldShowNotificationTypePreferences {
                    NavigationLink("preferences.notification-types",
                                   destination: NotificationTypesPreferencesView(
                                    viewModel: .init(identityContext: viewModel.identityContext)))
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
                                viewModel: .init(identityContext: viewModel.identityContext)))
                NavigationLink("preferences.startup-and-syncing",
                               destination: StartupAndSyncingPreferencesView(
                                identityContext: viewModel.identityContext))
            }
        }
        .navigationTitle("preferences")
    }
}

#if DEBUG
import PreviewViewModels

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(viewModel: .init(identityContext: .preview))
    }
}
#endif
