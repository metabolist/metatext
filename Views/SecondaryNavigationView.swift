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
                NavigationLink(
                    destination: IdentitiesView(viewModel: .init(identification: viewModel.identification))
                        .environmentObject(rootViewModel)
                        .environmentObject(viewModel.identification),
                    label: {
                        HStack {
                            KFImage(viewModel.identification.identity.image)
                                .downsampled(dimension: .avatarDimension, scaleFactor: displayScale)
                            VStack(alignment: .leading) {
                                if viewModel.identification.identity.authenticated {
                                    if let account = viewModel.identification.identity.account {
                                        CustomEmojiText(
                                            text: account.displayName,
                                            emojis: account.emojis,
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
                NavigationLink(destination: ListsView(viewModel: .init(identification: viewModel.identification))
                                .environmentObject(rootViewModel)
                                .environmentObject(viewModel.identification)) {
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
            }
            Section {
                NavigationLink(
                    destination: PreferencesView(viewModel: .init(identification: viewModel.identification))
                        .environmentObject(rootViewModel)
                        .environmentObject(viewModel.identification)) {
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
        SecondaryNavigationView(viewModel: NavigationViewModel(identification: .preview))
            .environmentObject(RootViewModel.preview)
    }
}
#endif
