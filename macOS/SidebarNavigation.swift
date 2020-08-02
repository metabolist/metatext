// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct SidebarNavigation: View {
    let identity: Identity
    @EnvironmentObject var sceneViewModel: SceneViewModel

    var sidebar: some View {
        List(selection: $sceneViewModel.selectedTopLevelNavigation) {
            ForEach(SceneViewModel.TopLevelNavigation.allCases) { topLevelNavigation in
                NavigationLink(destination: view(topLevelNavigation: topLevelNavigation)) {
                    Label(topLevelNavigation.title, systemImage: topLevelNavigation.systemImageName)
                }
                .accessibility(label: Text(topLevelNavigation.title))
                .tag(topLevelNavigation)
            }
        }
        .listStyle(SidebarListStyle())
    }

    var body: some View {
        NavigationView {
            sidebar
                .frame(minWidth: 100, idealWidth: 150, maxWidth: 200, maxHeight: .infinity)
        Text("Content")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private extension SidebarNavigation {
    func view(topLevelNavigation: SceneViewModel.TopLevelNavigation) -> some View {
        Group {
            switch topLevelNavigation {
            case .timelines:
                TimelineView()
            default: Text(topLevelNavigation.title)
            }
        }
    }
}

#if DEBUG
struct SidebarNavigation_Previews: PreviewProvider {
    static var previews: some View {
        SidebarNavigation(identity: .development)
            .environmentObject(SceneViewModel.development)
    }
}
#endif
