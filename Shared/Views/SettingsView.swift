// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import KingfisherSwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @EnvironmentObject var rootViewModel: RootViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.displayScale) var displayScale: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            NavigationView {
                Form {
                    HStack {
                        KFImage(viewModel.identity.image,
                                options: .downsampled(dimension: 50, scaleFactor: displayScale))
                        Text(viewModel.identity.handle)
                            .font(.subheadline)
                    }
                    NavigationLink(
                        "accounts",
                        destination: IdentitiesView(
                            viewModel: viewModel.identitiesViewModel())
                            .environmentObject(rootViewModel))
                }
                .navigationBarTitleAndItems(presentationMode: presentationMode)
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
    func navigationBarTitleAndItems(presentationMode: Binding<PresentationMode>) -> some View {
        #if os(iOS)
        return navigationBarTitle(Text("settings"), displayMode: .inline)
        .navigationBarItems(
            leading: Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill").imageScale(.large)
            })
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
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: .development)
            .environmentObject(RootViewModel.development)
    }
}
#endif
