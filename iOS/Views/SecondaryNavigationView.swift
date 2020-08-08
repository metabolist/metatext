// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import KingfisherSwiftUI

struct SecondaryNavigationView: View {
    @StateObject var viewModel: SecondaryNavigationViewModel
    @EnvironmentObject var rootViewModel: RootViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.displayScale) var displayScale: CGFloat

    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink(
                        destination: IdentitiesView(viewModel: viewModel.identitiesViewModel())
                            .environmentObject(rootViewModel),
                        label: {
                            HStack {
                                KFImage(viewModel.identity.image,
                                        options: .downsampled(dimension: 50, scaleFactor: displayScale))
                                VStack(alignment: .leading) {
                                    Text(viewModel.identity.handle)
                                        .font(.headline)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                    Spacer()
                                    Text("secondary-navigation.accounts")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        })
                }
                Section {
                    NavigationLink(
                        "secondary-navigation.preferences",
                        destination: PreferencesView(
                            viewModel: viewModel.preferencesViewModel()))
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
struct SecondaryNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        SecondaryNavigationView(viewModel: .development)
            .environmentObject(RootViewModel.development)
    }
}
#endif
