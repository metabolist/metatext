// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct NewStatusView: UIViewControllerRepresentable {
    let viewModelClosure: () -> NewStatusViewModel

    func makeUIViewController(context: Context) -> NewStatusViewController {
        NewStatusViewController(viewModel: viewModelClosure(), isShareExtension: false)
    }

    func updateUIViewController(_ uiViewController: NewStatusViewController, context: Context) {

    }
}

struct NewStatusView_Previews: PreviewProvider {
    static var previews: some View {
        NewStatusView { .preview }
    }
}
