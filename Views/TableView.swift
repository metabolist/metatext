// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct TableView: UIViewControllerRepresentable {
    @EnvironmentObject var identification: Identification
    @EnvironmentObject var rootViewModel: RootViewModel
    let viewModelClosure: () -> CollectionViewModel

    func makeUIViewController(context: Context) -> TableViewController {
        TableViewController(viewModel: viewModelClosure(), rootViewModel: rootViewModel, identification: identification)
    }

    func updateUIViewController(_ uiViewController: TableViewController, context: Context) {

    }
}

#if DEBUG
import PreviewViewModels

struct StatusListView_Previews: PreviewProvider {
    static var previews: some View {
        TableView { NavigationViewModel(identification: .preview).timelineViewModel }
    }
}
#endif
