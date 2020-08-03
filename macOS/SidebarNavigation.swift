// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import KingfisherSwiftUI
import struct Kingfisher.DownsamplingImageProcessor
import struct Kingfisher.RoundCornerImageProcessor

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
        .overlay(Pocket(identity: identity), alignment: .bottom)
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

    struct Pocket: View {
        let identity: Identity
        @EnvironmentObject var sceneViewModel: SceneViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                Button(action: { sceneViewModel.presentingSettings.toggle() }) {
                    KFImage(identity.account?.avatar
                                ?? identity.instance?.thumbnail,
                            options: [
                                .processor(
                                    DownsamplingImageProcessor(size: CGSize(width: 50, height: 50))
                                        .append(another: RoundCornerImageProcessor(radius: .widthFraction(0.5)))
                                ),
                                .scaleFactor(Screen.scale),
                                .cacheOriginalImage
                            ])
                        .placeholder { Image(systemName: "gear") }
                        .renderingMode(.original)
                        .resizable()
                    .padding(6)
                    .contentShape(Rectangle())
                }
                .frame(width: 50, height: 50)
                .accessibility(label: Text("Rewards"))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .buttonStyle(PlainButtonStyle())
            }
            .sheet(isPresented: $sceneViewModel.presentingSettings) {
                SettingsView(viewModel: SettingsViewModel(identity: identity))
                    .environmentObject(sceneViewModel)
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
