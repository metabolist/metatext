// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct RootView: View {
    @StateObject var viewModel: RootViewModel

    var body: some View {
        if let navigationViewModel = viewModel.navigationViewModel {
            MainNavigationView { navigationViewModel }
                .id(navigationViewModel.identityContext.identity.id)
                .environmentObject(viewModel)
                .transition(.opacity)
                .edgesIgnoringSafeArea(.all)
        } else {
            NavigationView {
                AddIdentityView(
                    viewModelClosure: { viewModel.addIdentityViewModel() },
                    displayWelcome: true)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarHidden(true)
            }
            .environmentObject(viewModel)
            .navigationViewStyle(StackNavigationViewStyle())
            .transition(.opacity)
        }
    }
}

#if DEBUG
import Combine
import PreviewViewModels

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(viewModel: .preview)
    }
}
#endif
