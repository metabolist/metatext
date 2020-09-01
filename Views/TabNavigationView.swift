// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import KingfisherSwiftUI
import ViewModels

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
                .navigationBarTitle(timelineTitle, displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack {
                            Text(timelineTitle)
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
                                Label(timelineTitle,
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

private extension TabNavigationView {
    var timelineTitle: String {
        switch viewModel.timeline {
        case .home:
            return NSLocalizedString("timelines.home", comment: "")
        case .local:
            return NSLocalizedString("timelines.local", comment: "")
        case .federated:
            return NSLocalizedString("timelines.federated", comment: "")
        case let .list(list):
            return list.title
        case let .tag(tag):
            return "#" + tag
        }
    }
}

extension TabNavigationViewModel.Tab {
    var title: String {
        switch self {
        case .timelines: return "Timelines"
        case .search: return "Search"
        case .notifications: return "Notifications"
        case .messages: return "Messages"
        }
    }

    var systemImageName: String {
        switch self {
        case .timelines: return "newspaper"
        case .search: return "magnifyingglass"
        case .notifications: return "bell"
        case .messages: return "envelope"
        }
    }
}

#if DEBUG
import PreviewViewModels

struct TabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        TabNavigationView(viewModel: .mock())
            .environmentObject(RootViewModel.mock())
    }
}
#endif
