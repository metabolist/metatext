// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @EnvironmentObject var sceneViewModel: SceneViewModel

    var body: some View {
        NavigationView {
            Form {
                Text(viewModel.identity.handle)
            }
                .navigationBarTitle(Text("settings"), displayMode: .inline)
                .navigationBarItems(
                    leading: Button {
                        sceneViewModel.presentingSettings.toggle()
                    } label: {
                        Image(systemName: "xmark.circle.fill").imageScale(.large)
                    })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: SettingsViewModel(identity: .development))
            .environmentObject(SceneViewModel.development)
    }
}
#endif
