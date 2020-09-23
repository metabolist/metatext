// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct CollectionView: UIViewControllerRepresentable {
    let viewModel: CollectionViewModel

    func makeUIViewController(context: Context) -> CollectionViewController {
        CollectionViewController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: CollectionViewController, context: Context) {

    }
}

#if DEBUG
import PreviewViewModels

struct StatusListView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionView(viewModel: NavigationViewModel(identification: .preview).viewModel(timeline: .home))
    }
}
#endif
