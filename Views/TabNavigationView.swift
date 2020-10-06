// Copyright © 2020 Metabolist. All rights reserved.

import KingfisherSwiftUI
import SwiftUI
import ViewModels

struct TabNavigationView: View {
    @ObservedObject var viewModel: NavigationViewModel
    @EnvironmentObject var rootViewModel: RootViewModel
    @Environment(\.displayScale) var displayScale: CGFloat

    var body: some View {
        Group {
            if viewModel.identification.identity.pending {
                pendingView
            } else {
                TabView(selection: $viewModel.selectedTab) {
                    ForEach(viewModel.tabs) { tab in
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
            }
        }
        .environmentObject(viewModel.identification)
        .sheet(isPresented: $viewModel.presentingSecondaryNavigation) {
            SecondaryNavigationView(viewModel: viewModel)
                .environmentObject(viewModel)
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
    var pendingView: some View {
        NavigationView {
            Text("pending.pending-confirmation")
                .navigationBarItems(leading: secondaryNavigationButton)
                .navigationTitle(viewModel.identification.identity.handle)
                .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    @ViewBuilder
    func view(tab: NavigationViewModel.Tab) -> some View {
        switch tab {
        case .timelines:
            TableView(viewModel: viewModel.viewModel(timeline: viewModel.timeline))
                .id(viewModel.timeline.id)
                .edgesIgnoringSafeArea(.all)
                .navigationTitle(viewModel.timeline.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack {
                            Text(viewModel.timeline.title)
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
                                Label(timeline.title,
                                      systemImage: timeline.systemImageName)
                            }
                        }
                    } label: {
                        Image(systemName: viewModel.timeline.systemImageName)
                            .padding([.leading, .top, .bottom])
                    })
        default: Text(tab.title)
        }
    }

    @ViewBuilder
    var secondaryNavigationButton: some View {
        Button {
            viewModel.presentingSecondaryNavigation.toggle()
        } label: {
            KFImage(viewModel.identification.identity.image,
                    options: .downsampled(dimension: 28, scaleFactor: displayScale))
                .placeholder { Image(systemName: "gear") }
                .renderingMode(.original)
                .contextMenu(ContextMenu {
                    ForEach(viewModel.recentIdentities) { recentIdentity in
                        Button {
                            rootViewModel.identitySelected(id: recentIdentity.id)
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
                .padding([.trailing, .top, .bottom])
        }
    }
}

private extension Timeline {
    var title: String {
        switch self {
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
        case .profile:
            return ""
        }
    }

    var systemImageName: String {
        switch self {
        case .home: return "house"
        case .local: return "person.3"
        case .federated: return "network"
        case .list: return "scroll"
        case .tag: return "number"
        case .profile: return "person"
        }
    }
}

extension NavigationViewModel.Tab {
    var title: String {
        switch self {
        case .timelines: return "Timelines"
        case .explore: return "Explore"
        case .notifications: return "Notifications"
        case .messages: return "Messages"
        }
    }

    var systemImageName: String {
        switch self {
        case .timelines: return "newspaper"
        case .explore: return "magnifyingglass"
        case .notifications: return "bell"
        case .messages: return "envelope"
        }
    }
}

#if DEBUG
import PreviewViewModels

struct TabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        TabNavigationView(viewModel: NavigationViewModel(identification: .preview))
            .environmentObject(Identification.preview)
            .environmentObject(RootViewModel.preview)
    }
}
#endif
