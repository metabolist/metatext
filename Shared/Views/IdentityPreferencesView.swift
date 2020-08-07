// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct IdentityPreferencesView: View {
    @StateObject var viewModel: IdentityPreferencesViewModel

    var body: some View {
        Form {
            Section(header: Text("preferences.posting")) {
                Toggle("preferences.use-preferences-from-server",
                       isOn: $viewModel.preferences.useServerPostingPreferences)
                VStack(alignment: .leading) {
                    Text("preferences.posting-default-visiblility")
                    Picker("", selection: $viewModel.preferences.postingDefaultVisibility,
                           content: {
                            Text("status.visibility.public").tag(Status.Visibility.public)
                            Text("status.visibility.unlisted").tag(Status.Visibility.unlisted)
                            Text("status.visibility.private").tag(Status.Visibility.private)
                           })
                        .pickerStyle(SegmentedPickerStyle())
                }
                .disabled(viewModel.preferences.useServerPostingPreferences)
                Toggle("preferences.posting-default-sensitive",
                       isOn: $viewModel.preferences.postingDefaultSensitive)
                .disabled(viewModel.preferences.useServerPostingPreferences)
            }
            Section(header: Text("preferences.reading")) {
                Toggle("preferences.use-preferences-from-server",
                       isOn: $viewModel.preferences.useServerReadingPreferences)
                VStack(alignment: .leading) {
                    Text("preferences.reading-expand-media")
                    Picker("", selection: $viewModel.preferences.readingExpandMedia,
                           content: {
                            Text("preferences.expand-media.default").tag(MastodonPreferences.ExpandMedia.default)
                            Text("preferences.expand-media.show-all").tag(MastodonPreferences.ExpandMedia.showAll)
                            Text("preferences.expand-media.hide-all").tag(MastodonPreferences.ExpandMedia.hideAll)
                           })
                        .pickerStyle(SegmentedPickerStyle())
                }
                .disabled(viewModel.preferences.useServerReadingPreferences)
                Toggle("preferences.reading-expand-spoilers",
                       isOn: $viewModel.preferences.readingExpandSpoilers)
                    .disabled(viewModel.preferences.useServerReadingPreferences)
            }
        }
        .navigationTitle("preferences.title.\(viewModel.handle)")
        .alertItem($viewModel.alertItem)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        IdentityPreferencesView(viewModel: .development)
    }
}
