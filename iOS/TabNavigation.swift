// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct TabNavigation: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel

    var body: some View {
        TabView(selection: $sceneViewModel.selectedTopLevelNavigation) {
            ForEach(SceneViewModel.TopLevelNavigation.allCases) { topLevelNavigation in
                NavigationView {
                    view(topLevelNavigation: topLevelNavigation)
                }
                .tabItem {
                    Label(topLevelNavigation.title, systemImage: topLevelNavigation.systemImageName)
                        .accessibility(label: Text(topLevelNavigation.title))
                }
                .tag(topLevelNavigation)
            }
        }
    }
}

private extension TabNavigation {
    func view(topLevelNavigation: SceneViewModel.TopLevelNavigation) -> some View {
        Group {
            switch topLevelNavigation {
            case .timelines:
                TimelineView()
                    .navigationBarTitle(sceneViewModel.identity?.handle ?? "", displayMode: .inline)
            default: Text(topLevelNavigation.title)
            }
        }
    }
}

// MARK: Preview

struct TabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        TabNavigation()
    }
}
