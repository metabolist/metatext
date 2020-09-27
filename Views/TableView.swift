// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct TableView: UIViewControllerRepresentable {
    let viewModel: CollectionViewModel

    func makeUIViewController(context: Context) -> TableViewController {
        TableViewController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: TableViewController, context: Context) {

    }
}

#if DEBUG
import PreviewViewModels

struct StatusListView_Previews: PreviewProvider {
    static var previews: some View {
        TableView(viewModel: NavigationViewModel(identification: .preview).viewModel(timeline: .home))
    }
}
#endif
