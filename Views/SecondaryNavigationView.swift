// Copyright © 2020 Metabolist. All rights reserved.

import KingfisherSwiftUI
import SwiftUI
import ViewModels

struct SecondaryNavigationView: View {
    @EnvironmentObject var identification: Identification
    @EnvironmentObject var tabNavigationViewModel: TabNavigationViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.displayScale) var displayScale: CGFloat

    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink(
                        destination: IdentitiesView(viewModel: .init(identification: identification)),
                        label: {
                            HStack {
                                KFImage(tabNavigationViewModel.identity.image,
                                        options: .downsampled(dimension: 50, scaleFactor: displayScale))
                                VStack(alignment: .leading) {
                                    if let account = tabNavigationViewModel.identity.account {
                                        CustomEmojiText(
                                            text: account.displayName,
                                            emoji: account.emojis,
                                            textStyle: .headline)
                                    }
                                    Text(tabNavigationViewModel.identity.handle)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
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
                        presentationMode.wrappedValue.dismiss()
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
        SecondaryNavigationView()
            .environmentObject(Identification.preview)
            .environmentObject(TabNavigationViewModel(identification: .preview))
    }
}
#endif
