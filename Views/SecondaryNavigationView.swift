// Copyright © 2020 Metabolist. All rights reserved.

import KingfisherSwiftUI
import SwiftUI
import ViewModels

struct SecondaryNavigationView: View {
    @ObservedObject var viewModel: TabNavigationViewModel
    @EnvironmentObject var identification: Identification
    @EnvironmentObject var rootViewModel: RootViewModel
    @Environment(\.displayScale) var displayScale: CGFloat

    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink(
                        destination: IdentitiesView(viewModel: .init(identification: identification)),
                        label: {
                            HStack {
                                KFImage(identification.identity.image,
                                        options: .downsampled(dimension: 50, scaleFactor: displayScale))
                                VStack(alignment: .leading) {
                                    if identification.identity.authenticated {
                                        if let account = identification.identity.account {
                                            CustomEmojiText(
                                                text: account.displayName,
                                                emoji: account.emojis,
                                                textStyle: .headline)
                                        }
                                        Text(identification.identity.handle)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)
                                    } else {
                                        Text(identification.identity.handle)
                                            .font(.headline)
                                        if let instance = identification.identity.instance {
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
                    NavigationLink(destination: ListsView(viewModel: .init(identification: identification))) {
                        Label("secondary-navigation.lists", systemImage: "scroll")
                    }
                }
                Section {
                    NavigationLink(
                        "secondary-navigation.preferences",
                        destination: PreferencesView(
                            viewModel: .init(identification: identification)))
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
    }
}

#if DEBUG
import PreviewViewModels

struct SecondaryNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        SecondaryNavigationView(viewModel: TabNavigationViewModel(identification: .preview))
            .environmentObject(Identification.preview)
            .environmentObject(RootViewModel.preview)
    }
}
#endif
