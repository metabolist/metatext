// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import KingfisherSwiftUI

struct SidebarNavigationView: View {
    @StateObject var viewModel: SidebarNavigationViewModel
    @EnvironmentObject var rootViewModel: RootViewModel

    var sidebar: some View {
        List(selection: $viewModel.selectedTab) {
            ForEach(SidebarNavigationViewModel.Tab.allCases) { tab in
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

private extension SidebarNavigationView {
    func view(topLevelNavigation: SidebarNavigationViewModel.Tab) -> some View {
        Group {
            switch topLevelNavigation {
            case .timelines:
                TimelineView()
            default: Text(topLevelNavigation.title)
            }
        }
    }

    struct Pocket: View {
        @EnvironmentObject var viewModel: SidebarNavigationViewModel
        @EnvironmentObject var rootViewModel: RootViewModel
        @Environment(\.displayScale) var displayScale: CGFloat

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                Button(action: { /*viewModel.presentingSecondaryNavigation.toggle()*/ }) {
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
        }
    }
}

#if DEBUG
struct SidebarNavigation_Previews: PreviewProvider {
    static var previews: some View {
        SidebarNavigationView(viewModel: .development)
            .environmentObject(RootViewModel.development)
    }
}
#endif
