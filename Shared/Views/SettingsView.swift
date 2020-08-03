// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import KingfisherSwiftUI
import struct Kingfisher.DownsamplingImageProcessor
import struct Kingfisher.RoundCornerImageProcessor

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @EnvironmentObject var sceneViewModel: SceneViewModel

    var body: some View {
        VStack(spacing: 0) {
            NavigationView {
                Form {
                    HStack {
                        KFImage(viewModel.identity.account?.avatar,
                                options: [
                                    .processor(
                                        DownsamplingImageProcessor(size: CGSize(width: 50, height: 50))
                                            .append(another: RoundCornerImageProcessor(radius: .widthFraction(0.5)))
                                    ),
                                    .scaleFactor(Screen.scale),
                                    .cacheOriginalImage
                                ])
                        Text(viewModel.identity.handle)
                            .font(.subheadline)
                    }
                }
                .navigationBarTitleAndItems(sceneViewModel: sceneViewModel)
            }
            .navigationViewStyle
            #if os(macOS)
            Divider()
            HStack {
                Spacer()
                Button(action: { sceneViewModel.presentingSettings.toggle() }) {
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
    func navigationBarTitleAndItems(sceneViewModel: SceneViewModel) -> some View {
        #if os(iOS)
        return navigationBarTitle(Text("settings"), displayMode: .inline)
        .navigationBarItems(
            leading: Button {
                sceneViewModel.presentingSettings.toggle()
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
        SettingsView(viewModel: SettingsViewModel(identity: .development))
            .environmentObject(SceneViewModel.development)
    }
}
#endif
