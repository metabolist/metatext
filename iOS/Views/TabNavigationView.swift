// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import KingfisherSwiftUI

struct TabNavigationView: View {
    @ObservedObject var viewModel: TabNavigationViewModel
    @EnvironmentObject var rootViewModel: RootViewModel
    @Environment(\.displayScale) var displayScale: CGFloat

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            ForEach(TabNavigationViewModel.Tab.allCases) { tab in
                NavigationView {
                    view(tab: tab)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImageName)
                        .accessibility(label: Text(tab.title))
                }
                .tag(tab)
            }
        }
        .sheet(isPresented: $viewModel.presentingSecondaryNavigation) {
            SecondaryNavigationView(viewModel: viewModel.secondaryNavigationViewModel())
                .environmentObject(rootViewModel)
        }
        .alertItem($viewModel.alertItem)
        .onAppear(perform: viewModel.refreshIdentity)
        .onReceive(NotificationCenter.default
                    .publisher(for: UIScene.willEnterForegroundNotification)
                    .map { _ in () },
                   perform: viewModel.refreshIdentity)
    }
}

private extension TabNavigationView {
    @ViewBuilder
    func view(tab: TabNavigationViewModel.Tab) -> some View {
        switch tab {
        case .timelines:
            StatusListView(viewModel: viewModel.timelineViewModel)
                .navigationBarTitle(viewModel.identity.handle, displayMode: .inline)
                .navigationBarItems(
                    leading: Button {
                        viewModel.presentingSecondaryNavigation.toggle()
                    } label: {
                        KFImage(viewModel.identity.image,
                                options: .downsampled(dimension: 28, scaleFactor: displayScale))
                            .placeholder { Image(systemName: "gear") }
                            .renderingMode(.original)
                            .contextMenu(ContextMenu {
                                ForEach(viewModel.recentIdentities) { recentIdentity in
                                    Button {
                                        rootViewModel.newIdentitySelected(id: recentIdentity.id)
                                    } label: {
                                        Label(
                                            title: { Text(recentIdentity.handle) },
                                            icon: {
                                                KFImage(recentIdentity.image,
                                                        options: .downsampled(dimension: 28, scaleFactor: displayScale))
                                                    .renderingMode(.original)
                                            })
                                    }
                                }
                            })
                    })
        default: Text(tab.title)
        }
    }
}

#if DEBUG
struct TabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        TabNavigationView(viewModel: .development)
            .environmentObject(RootViewModel.development)
    }
}
#endif
