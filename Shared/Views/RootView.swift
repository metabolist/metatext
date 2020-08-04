// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct RootView: View {
    @StateObject var viewModel: RootViewModel

    var body: some View {
        ZStack {
            if let mainNavigationViewModel = viewModel.mainNavigationViewModel {
                Self.mainNavigation(mainNavigationViewModel: mainNavigationViewModel)
                    .environmentObject(viewModel)
            } else {
                AddIdentityView(viewModel: viewModel.addIdentityViewModel())
            }
        }
    }
}

private extension RootView {
    @ViewBuilder
    private static func mainNavigation(mainNavigationViewModel: MainNavigationViewModel) -> some View {
        #if os(macOS)
        SidebarNavigation(viewModel: mainNavigationViewModel)
            .frame(minWidth: 900, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
        #else
        TabNavigation(viewModel: mainNavigationViewModel)
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
