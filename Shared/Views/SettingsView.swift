// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import KingfisherSwiftUI
import struct Kingfisher.DownsamplingImageProcessor
import struct Kingfisher.RoundCornerImageProcessor

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @EnvironmentObject var sceneViewModel: SceneViewModel

    var body: some View {
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
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: SettingsViewModel(identity: .development))
            .environmentObject(SceneViewModel.development)
    }
}
#endif
