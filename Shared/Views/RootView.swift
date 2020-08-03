// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct RootView: View {
    @StateObject var viewModel: RootViewModel

    var body: some View {
        if
            let identityID = viewModel.identityID,
            let mainNavigationViewModel = viewModel.mainNavigationViewModel(identityID: identityID) {
            Self.mainNavigation(viewModel: mainNavigationViewModel)
        } else {
            addIdentity
        }
    }
}

private extension RootView {
    private static func mainNavigation(viewModel: MainNavigationViewModel) -> some View {
        #if os(macOS)
        return SidebarNavigation().environmentObject(viewModel)
            .frame(minWidth: 900, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
        #else
        return TabNavigation().environmentObject(viewModel)
        #endif
    }

    private var addIdentity: some View {
        AddIdentityView(viewModel: viewModel.addIdentityViewModel())
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(viewModel: .development)
    }
}
#endif
