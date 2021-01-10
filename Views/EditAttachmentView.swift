// Copyright © 2021 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct EditAttachmentView: UIViewControllerRepresentable {
    let viewModelsClosure: () -> (AttachmentViewModel, CompositionViewModel)

    func makeUIViewController(context: Context) -> EditAttachmentViewController {
        let (attachmentViewModel, compositionViewModel) = viewModelsClosure()

        return EditAttachmentViewController(viewModel: attachmentViewModel, parentViewModel: compositionViewModel)
    }

    func updateUIViewController(_ uiViewController: EditAttachmentViewController, context: Context) {

    }
}
