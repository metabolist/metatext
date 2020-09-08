// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct RootView: View {
    @StateObject var viewModel: RootViewModel

    var body: some View {
        if let identification = viewModel.identification {
            TabNavigationView()
                .id(UUID())
                .environmentObject(identification)
                .environmentObject(TabNavigationViewModel(identification: identification))
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
import Combine
import PreviewViewModels

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(viewModel: .preview)
    }
}
#endif
