// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct RootView: View {
    @StateObject var viewModel: RootViewModel

    var body: some View {
        if let tabNavigationViewModel = viewModel.tabNavigationViewModel {
            TabNavigationView(viewModel: tabNavigationViewModel)
                .id(UUID())
                .environmentObject(viewModel)
                .transition(.opacity)
        } else {
            AddIdentityView(viewModel: viewModel.addIdentityViewModel())
                .environmentObject(viewModel)
                .transition(.opacity)
        }
    }
}

#if DEBUG
import PreviewViewModels

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(viewModel: .mock())
    }
}
#endif
