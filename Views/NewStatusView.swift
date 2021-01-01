// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct NewStatusView: UIViewControllerRepresentable {
    let viewModelClosure: () -> NewStatusViewModel

    func makeUIViewController(context: Context) -> NewStatusViewController {
        NewStatusViewController(viewModel: viewModelClosure())
    }

    func updateUIViewController(_ uiViewController: NewStatusViewController, context: Context) {

    }
}
