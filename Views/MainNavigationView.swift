// Copyright © 2021 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct MainNavigationView: UIViewControllerRepresentable {
    let viewModelClosure: () -> NavigationViewModel
    @EnvironmentObject var rootViewModel: RootViewModel
    @EnvironmentObject var identification: Identification

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
        MainNavigationView { NavigationViewModel(identification: .preview) }
            .environmentObject(Identification.preview)
            .environmentObject(RootViewModel.preview)
    }
}
#endif
