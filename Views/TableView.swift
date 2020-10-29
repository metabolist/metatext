// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct TableView: UIViewControllerRepresentable {
    @EnvironmentObject var identification: Identification
    let viewModel: CollectionViewModel

    func makeUIViewController(context: Context) -> TableViewController {
        TableViewController(viewModel: viewModel, identification: identification)
    }

    func updateUIViewController(_ uiViewController: TableViewController, context: Context) {

    }
}

#if DEBUG
import PreviewViewModels

struct StatusListView_Previews: PreviewProvider {
    static var previews: some View {
        TableView(viewModel: NavigationViewModel(identification: .preview).timelineViewModel)
    }
}
#endif
