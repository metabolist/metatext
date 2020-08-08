// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

#if os(macOS)
typealias MainNavigationViewModel = SidebarNavigationViewModel
#else
typealias MainNavigationViewModel = TabNavigationViewModel
#endif

struct RootView: View {
    @StateObject var viewModel: RootViewModel

    var body: some View {
        if let id = viewModel.identityID,
           let mainNavigationViewModel = viewModel.mainNavigationViewModel(identityID: id) {
            Self.mainNavigation(mainNavigationViewModel: mainNavigationViewModel)
                .id(id)
                .environmentObject(viewModel)
                .transition(.opacity)
        } else {
            AddIdentityView(viewModel: viewModel.addIdentityViewModel())
                .environmentObject(viewModel)
                .transition(.opacity)
        }
    }
}

private extension RootView {
    @ViewBuilder
    private static func mainNavigation(mainNavigationViewModel: MainNavigationViewModel) -> some View {
        #if os(macOS)
        SidebarNavigationView(viewModel: mainNavigationViewModel)
            .frame(minWidth: 900, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
        #else
        TabNavigationView(viewModel: mainNavigationViewModel)
        #endif
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(viewModel: .development)
    }
}
#endif
