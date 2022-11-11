// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import UIKit
import ViewModels

struct RootView: View {
    @StateObject var viewModel: RootViewModel
    @State private var previousColorScheme: AppPreferences.ColorScheme = .system
    var appPreferencesPublisher: AnyPublisher<AppPreferences, Never> {
        viewModel.navigationViewModel?.identityContext.$appPreferences.eraseToAnyPublisher()
            ?? Empty<AppPreferences, Never>().eraseToAnyPublisher()
    }

    var body: some View {
        Group {
            if let navigationViewModel = viewModel.navigationViewModel {
                MainNavigationView { navigationViewModel }
                    .id(navigationViewModel.identityContext.identity.id)
                    .environmentObject(viewModel)
                    .transition(.opacity)
                    .edgesIgnoringSafeArea(.all)
            } else {
                NavigationView {
                    AddIdentityView(
                        viewModelClosure: { viewModel.addIdentityViewModel() },
                        displayWelcome: true)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarHidden(true)
                }
                .environmentObject(viewModel)
                .navigationViewStyle(StackNavigationViewStyle())
                .transition(.opacity)
            }
        }
        .onReceive(appPreferencesPublisher) { preferences in
            if preferences.colorScheme != previousColorScheme {
                self.previousColorScheme = preferences.colorScheme
                setColorScheme(preferences.colorScheme)
            }
        }
    }

    private func setColorScheme(_ colorScheme: AppPreferences.ColorScheme) {
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        let window = windowScenes?.windows.first
        window?.overrideUserInterfaceStyle = colorScheme.uiKit
    }
}

extension AppPreferences.ColorScheme {
    var uiKit: UIUserInterfaceStyle {
        switch self {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

#if DEBUG
import Combine
import PreviewViewModels

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(viewModel: .preview)
    }
}
#endif
