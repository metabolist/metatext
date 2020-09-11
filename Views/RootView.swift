// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct RootView: View {
    @StateObject var viewModel: RootViewModel

    var body: some View {
        if let navigationViewModel = viewModel.navigationViewModel {
            TabNavigationView(viewModel: navigationViewModel)
                .id(navigationViewModel.identification.identity.id)
                .environmentObject(viewModel)
                .transition(.opacity)
        } else {
            NavigationView {
                AddIdentityView(viewModel: viewModel.addIdentityViewModel())
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarHidden(true)
            }
            .environmentObject(viewModel)
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
