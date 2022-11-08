// Copyright © 2021 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct MainNavigationView: UIViewControllerRepresentable {
    let viewModelClosure: () -> NavigationViewModel
    @EnvironmentObject var rootViewModel: RootViewModel

    func makeUIViewController(context: Context) -> MainNavigationViewController {
        MainNavigationViewController(
            viewModel: viewModelClosure(),
            rootViewModel: rootViewModel)
    }

    func updateUIViewController(_ uiViewController: MainNavigationViewController, context: Context) {

    }
}

#if DEBUG
import PreviewViewModels

struct MainNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        MainNavigationView { NavigationViewModel(identityContext: .preview, environment: .preview) }
            .environmentObject(RootViewModel.preview)
    }
}
#endif
