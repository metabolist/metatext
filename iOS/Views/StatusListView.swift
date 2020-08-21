// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct StatusListView: UIViewControllerRepresentable {
    let viewModel: StatusesViewModel

    func makeUIViewController(context: Context) -> StatusListViewController {
        StatusListViewController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: StatusListViewController, context: Context) {

    }
}
