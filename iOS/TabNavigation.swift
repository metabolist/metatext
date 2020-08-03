// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import KingfisherSwiftUI
import struct Kingfisher.DownsamplingImageProcessor

struct TabNavigation: View {
    @EnvironmentObject var viewModel: MainNavigationViewModel

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            ForEach(MainNavigationViewModel.Tab.allCases) { tab in
                NavigationView {
                    view(tab: tab)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImageName)
                        .accessibility(label: Text(tab.title))
                }
                .tag(tab)
            }
        }
        .sheet(isPresented: $viewModel.presentingSettings) {
            SettingsView(viewModel: viewModel.settingsViewModel())
                .environmentObject(viewModel)
        }
        .onAppear { viewModel.refreshIdentity() }
    }
}

private extension TabNavigation {
    func view(tab: MainNavigationViewModel.Tab) -> some View {
        Group {
            switch tab {
            case .timelines:
                TimelineView()
                    .navigationBarTitle(viewModel.handle, displayMode: .inline)
                    .navigationBarItems(
                        leading: Button {
                            viewModel.presentingSettings.toggle()
                        } label: {
                            KFImage(viewModel.image,
                                    options: [
                                        .processor(
                                            DownsamplingImageProcessor(size: CGSize(width: 28, height: 28))
                                        ),
                                        .scaleFactor(Screen.scale),
                                        .cacheOriginalImage
                                    ])
                                .placeholder { Image(systemName: "gear") }
                                .renderingMode(.original)
                                .clipShape(Circle())
                        })
            default: Text(tab.title)
            }
        }
    }
}

#if DEBUG
struct TabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        TabNavigation()
            .environmentObject(MainNavigationViewModel.development)
    }
}
#endif
