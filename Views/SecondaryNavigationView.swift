// Copyright © 2020 Metabolist. All rights reserved.

import KingfisherSwiftUI
import SwiftUI
import ViewModels

struct SecondaryNavigationView: View {
    @ObservedObject var viewModel: NavigationViewModel
    @EnvironmentObject var rootViewModel: RootViewModel
    @Environment(\.displayScale) var displayScale: CGFloat

    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink(
                        destination: IdentitiesView(viewModel: .init(identification: viewModel.identification)),
                        label: {
                            HStack {
                                KFImage(viewModel.identification.identity.image,
                                        options: .downsampled(dimension: .avatarDimension, scaleFactor: displayScale))
                                VStack(alignment: .leading) {
                                    if viewModel.identification.identity.authenticated {
                                        if let account = viewModel.identification.identity.account {
                                            CustomEmojiText(
                                                text: account.displayName,
                                                emoji: account.emojis,
                                                textStyle: .headline)
                                        }
                                        Text(viewModel.identification.identity.handle)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)
                                    } else {
                                        Text(viewModel.identification.identity.handle)
                                            .font(.headline)
                                        if let instance = viewModel.identification.identity.instance {
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
                    NavigationLink(destination: ListsView(viewModel: .init(identification: viewModel.identification))) {
                        Label("secondary-navigation.lists", systemImage: "scroll")
                    }
                    NavigationLink(destination: TableView(viewModel: viewModel.favoritesViewModel())
                                    .navigationTitle(Text("favorites"))) {
                        Label("favorites", systemImage: "star")
                    }
                    NavigationLink(destination: TableView(viewModel: viewModel.bookmarksViewModel())
                                    .navigationTitle(Text("bookmarks"))) {
                        Label("bookmarks", systemImage: "bookmark")
                    }
                }
                Section {
                    NavigationLink(
                        "secondary-navigation.preferences",
                        destination: PreferencesView(
                            viewModel: .init(identification: viewModel.identification)))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.presentingSecondaryNavigation = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(viewModel.identification)
    }
}

#if DEBUG
import PreviewViewModels

struct SecondaryNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        SecondaryNavigationView(viewModel: NavigationViewModel(identification: .preview))
            .environmentObject(RootViewModel.preview)
    }
}
#endif
