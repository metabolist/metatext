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
                .environmentObject(viewModel)
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
            StatusListView(viewModel: viewModel.viewModel(timeline: viewModel.timeline))
                .id(viewModel.timeline.id)
                .edgesIgnoringSafeArea(.all)
                .navigationBarTitle(viewModel.title(timeline: viewModel.timeline), displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack {
                            Text(viewModel.title(timeline: viewModel.timeline))
                                .font(.headline)
                            Text(viewModel.timelineSubtitle)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationBarItems(
                    leading: secondaryNavigationButton,
                    trailing: Menu {
                        ForEach(viewModel.timelinesAndLists) { timeline in
                            Button {
                                viewModel.timeline = timeline
                            } label: {
                                Label(viewModel.title(timeline: timeline),
                                      systemImage: viewModel.systemImageName(timeline: timeline))
                            }
                        }
                    } label: {
                        Image(systemName: viewModel.systemImageName(timeline: viewModel.timeline))
                    })
        default: Text(tab.title)
        }
    }

    @ViewBuilder
    var secondaryNavigationButton: some View {
        Button {
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
