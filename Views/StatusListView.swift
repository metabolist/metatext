// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct StatusListView: UIViewControllerRepresentable {
    let viewModel: StatusListViewModel

    func makeUIViewController(context: Context) -> StatusListViewController {
        StatusListViewController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: StatusListViewController, context: Context) {

    }
}

#if DEBUG
import PreviewViewModels

struct StatusListView_Previews: PreviewProvider {
    static var previews: some View {
        StatusListView(viewModel: .mock())
    }
}
#endif
