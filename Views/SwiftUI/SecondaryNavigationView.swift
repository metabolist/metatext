// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct SecondaryNavigationView: View {
    @ObservedObject var viewModel: NavigationViewModel
    @EnvironmentObject var rootViewModel: RootViewModel
    @Environment(\.displayScale) var displayScale: CGFloat

    var body: some View {
        Form {
            Section {
                if let id = viewModel.identityContext.identity.account?.id {
                    Button {
                        viewModel.navigateToProfile(id: id)
                    } label: {
                        Label {
                            Text("secondary-navigation.my-profile").foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "person.crop.square")
                        }
                    }
                }
                NavigationLink(
                    destination: IdentitiesView { .init(identityContext: viewModel.identityContext) }
                        .environmentObject(rootViewModel)) {
                    Label("secondary-navigation.accounts", systemImage: "rectangle.stack.person.crop")
                }
            }
            if viewModel.identityContext.identity.authenticated && !viewModel.identityContext.identity.pending {
                Section {
                    NavigationLink(destination: ListsView(viewModel: .init(identityContext: viewModel.identityContext))
                                    .environmentObject(rootViewModel)) {
                        Label("secondary-navigation.lists", systemImage: "scroll")
                    }
                    ForEach([Timeline.favorites, Timeline.bookmarks]) { timeline in
                        Button {
                            viewModel.navigate(timeline: timeline)
                        } label: {
                            Label {
                                Text(timeline.title).foregroundColor(.primary)
                            } icon: {
                                Image(systemName: timeline.systemImageName)
                            }
                        }
                    }
                    if let followRequestCount = viewModel.identityContext.identity.account?.followRequestCount,
                       followRequestCount > 0 {
                        Button {
                            viewModel.navigateToFollowerRequests()
                        } label: {
                            Label {
                                HStack {
                                    Text("follow-requests").foregroundColor(.primary)
                                    Spacer()
                                    Text(verbatim: String(followRequestCount))
                                }
                            } icon: {
                                Image(systemName: "person.badge.plus")
                            }
                        }
                    }
                }
            }
            Section {
                NavigationLink(
                    destination: PreferencesView(viewModel: .init(identityContext: viewModel.identityContext))
                        .environmentObject(rootViewModel)) {
                    Label("secondary-navigation.preferences", systemImage: "gear")
                }
                NavigationLink(
                    destination: AboutView()
                        .environmentObject(rootViewModel)) {
                    Label("secondary-navigation.about", systemImage: "info.circle")
                }
            }
        }
    }
}

#if DEBUG
import PreviewViewModels

struct SecondaryNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        SecondaryNavigationView(viewModel: NavigationViewModel(identityContext: .preview))
            .environmentObject(RootViewModel.preview)
    }
}
#endif
