// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct TableView: UIViewControllerRepresentable {
    @EnvironmentObject var rootViewModel: RootViewModel
    let viewModelClosure: () -> CollectionViewModel

    func makeUIViewController(context: Context) -> TableViewController {
        TableViewController(viewModel: viewModelClosure(),
                            rootViewModel: rootViewModel)
    }

    func updateUIViewController(_ uiViewController: TableViewController, context: Context) {

    }
}
