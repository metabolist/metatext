// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        if sceneViewModel.identity != nil {
            mainNavigation
                .onChange(of: scenePhase) {
                    if case .active = $0 {
                        sceneViewModel.refreshIdentity()
                    }
                }
                .alertItem($sceneViewModel.alertItem)
        } else {
            addIdentity
        }
    }
}

private extension ContentView {
    private var mainNavigation: some View {
        #if os(macOS)
        return SidebarNavigation().frame(minWidth: 900, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
        #else
        return TabNavigation()
        #endif
    }

    private var addIdentity: some View {
        AddIdentityView(viewModel: sceneViewModel.addIdentityViewModel())
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
