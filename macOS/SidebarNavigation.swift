// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import KingfisherSwiftUI
import struct Kingfisher.DownsamplingImageProcessor
import struct Kingfisher.RoundCornerImageProcessor

struct SidebarNavigation: View {
    @StateObject var viewModel: MainNavigationViewModel
    @EnvironmentObject var rootViewModel: RootViewModel

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
        .overlay(Pocket()
                    .environmentObject(viewModel)
                    .environmentObject(rootViewModel),
                 alignment: .bottom)
        .listStyle(SidebarListStyle())
        .onAppear(perform: viewModel.refreshIdentity)
        .onReceive(NotificationCenter.default
                    .publisher(for: NSWindow.didBecomeKeyNotification)
                    .dropFirst()
                    .map { _ in () },
                   perform: viewModel.refreshIdentity)
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
        @EnvironmentObject var rootViewModel: RootViewModel
        @Environment(\.displayScale) var displayScale: CGFloat

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                Button(action: { viewModel.presentingSettings.toggle() }) {
                    KFImage(viewModel.identity.image,
                             options: .downsampled(dimension: 28, scaleFactor: displayScale))
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
                SecondaryNavigationView(viewModel: viewModel.settingsViewModel())
                    .environmentObject(viewModel)
                    .environmentObject(rootViewModel)
            }
        }
    }
}

#if DEBUG
struct SidebarNavigation_Previews: PreviewProvider {
    static var previews: some View {
        SidebarNavigation(viewModel: .development)
            .environmentObject(RootViewModel.development)
    }
}
#endif
