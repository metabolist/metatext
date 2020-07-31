// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        if let identity = sceneViewModel.identity {
            mainNavigation(identity: identity)
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
    private func mainNavigation(identity: Identity) -> some View {
        #if os(macOS)
        return SidebarNavigation().frame(minWidth: 900, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
        #else
        return TabNavigation(identity: identity)
        #endif
    }

    private var addIdentity: some View {
        AddIdentityView(viewModel: sceneViewModel.addIdentityViewModel())
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SceneViewModel.development)
    }
}
#endif
