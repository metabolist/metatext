// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import KingfisherSwiftUI
import struct Kingfisher.DownsamplingImageProcessor
import struct Kingfisher.RoundCornerImageProcessor

struct TabNavigation: View {
    let identity: Identity
    @EnvironmentObject var sceneViewModel: SceneViewModel

    var body: some View {
        TabView(selection: $sceneViewModel.selectedTopLevelNavigation) {
            ForEach(SceneViewModel.TopLevelNavigation.allCases) { topLevelNavigation in
                NavigationView {
                    view(topLevelNavigation: topLevelNavigation)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label(topLevelNavigation.title, systemImage: topLevelNavigation.systemImageName)
                        .accessibility(label: Text(topLevelNavigation.title))
                }
                .tag(topLevelNavigation)
            }
        }
        .sheet(isPresented: $sceneViewModel.presentingSettings) {
            SettingsView(viewModel: SettingsViewModel(identity: identity))
                .environmentObject(sceneViewModel)
        }
    }
}

private extension TabNavigation {
    func view(topLevelNavigation: SceneViewModel.TopLevelNavigation) -> some View {
        Group {
            switch topLevelNavigation {
            case .timelines:
                TimelineView()
                    .navigationBarTitle(identity.handle, displayMode: .inline)
                    .navigationBarItems(
                        leading: Button {
                            sceneViewModel.presentingSettings.toggle()
                        } label: {
                            KFImage(identity.account?.avatar
                                        ?? identity.instance?.thumbnail,
                                    options: [
                                        .processor(
                                            DownsamplingImageProcessor(size: CGSize(width: 28, height: 28))
                                                .append(another: RoundCornerImageProcessor(radius: .widthFraction(0.5)))
                                        ),
                                        .scaleFactor(Screen.scale),
                                        .cacheOriginalImage
                                    ])
                                .placeholder { Image(systemName: "gear") }
                                .renderingMode(.original)
                        })
            default: Text(topLevelNavigation.title)
            }
        }
    }
}

// MARK: Preview

#if DEBUG
struct TabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        TabNavigation(identity: .development)
            .environmentObject(SceneViewModel.development)
    }
}
#endif
