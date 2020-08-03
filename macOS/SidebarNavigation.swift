// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import KingfisherSwiftUI
import struct Kingfisher.DownsamplingImageProcessor
import struct Kingfisher.RoundCornerImageProcessor

struct SidebarNavigation: View {
    @EnvironmentObject var viewModel: MainNavigationViewModel

    var sidebar: some View {
        List(selection: $viewModel.selectedTab) {
            ForEach(MainNavigationViewModel.Tab.allCases) { tab in
                NavigationLink(destination: view(topLevelNavigation: tab)) {
                    Label(tab.title, systemImage: tab.systemImageName)
                }
                .accessibility(label: Text(tab.title))
                .tag(tab)
            }
        }
        .overlay(Pocket(), alignment: .bottom)
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
    func view(topLevelNavigation: MainNavigationViewModel.Tab) -> some View {
        Group {
            switch topLevelNavigation {
            case .timelines:
                TimelineView()
            default: Text(topLevelNavigation.title)
            }
        }
    }

    struct Pocket: View {
        @EnvironmentObject var viewModel: MainNavigationViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                Button(action: { viewModel.presentingSettings.toggle() }) {
                    KFImage(viewModel.image,
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
            .sheet(isPresented: $viewModel.presentingSettings) {
                SettingsView(viewModel: viewModel.settingsViewModel())
                    .environmentObject(viewModel)
            }
        }
    }
}

#if DEBUG
struct SidebarNavigation_Previews: PreviewProvider {
    static var previews: some View {
        SidebarNavigation()
            .environmentObject(MainNavigationViewModel.development)
    }
}
#endif
