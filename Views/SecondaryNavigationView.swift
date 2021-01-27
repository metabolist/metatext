// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
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
                    destination: IdentitiesView(viewModel: .init(identityContext: viewModel.identityContext))
                        .environmentObject(rootViewModel),
                    label: {
                        HStack {
                            KFImage(viewModel.identityContext.identity.image)
                                .downsampled(dimension: .avatarDimension, scaleFactor: displayScale)
                            VStack(alignment: .leading) {
                                if viewModel.identityContext.identity.authenticated {
                                    if let account = viewModel.identityContext.identity.account {
                                        CustomEmojiText(
                                            text: account.displayName,
                                            emojis: account.emojis,
                                            textStyle: .headline)
                                    }
                                    Text(viewModel.identityContext.identity.handle)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                } else {
                                    Text(viewModel.identityContext.identity.handle)
                                        .font(.headline)
                                    if let instance = viewModel.identityContext.identity.instance {
                                        Text(instance.uri)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)
                                    }
                                }

                                Spacer()
                                Text("secondary-navigation.manage-accounts")
                                    .font(.subheadline)
                            }
                            .padding()
                        }
                    })
            }
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
            Section {
                NavigationLink(
                    destination: PreferencesView(viewModel: .init(identityContext: viewModel.identityContext))
                        .environmentObject(rootViewModel)) {
                    Label("secondary-navigation.preferences", systemImage: "gear")
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
