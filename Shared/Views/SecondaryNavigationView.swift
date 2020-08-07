// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import KingfisherSwiftUI

struct SecondaryNavigationView: View {
    @StateObject var viewModel: SecondaryNavigationViewModel
    @EnvironmentObject var rootViewModel: RootViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.displayScale) var displayScale: CGFloat

    var body: some View {
        VStack(spacing: 0) {
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
                        NavigationLink(
                            "secondary-navigation.identity-preferences",
                            destination: IdentityPreferencesView(viewModel: viewModel.identityPreferencesViewModel()))
                    }
                }
                .navigationItems(presentationMode: presentationMode)
            }
            .navigationViewStyle
            #if os(macOS)
            Divider()
            HStack {
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Done")
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()

            #endif
        }
        .frame
    }
}

private extension View {
    func navigationItems(presentationMode: Binding<PresentationMode>) -> some View {
        #if os(iOS)
        return navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
            }
        #else
        return self
        #endif
    }

    var navigationViewStyle: some View {
        #if os(iOS)
        return navigationViewStyle(StackNavigationViewStyle())
        #else
        return self
        #endif
    }

    var frame: some View {
        #if os(macOS)
        return frame(minWidth: 400, maxWidth: 600, minHeight: 350, maxHeight: 500)
        #else
        return self
        #endif
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
