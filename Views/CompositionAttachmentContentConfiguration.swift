// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

struct CompositionAttachmentContentConfiguration {
    let viewModel: CompositionAttachmentViewModel
}

extension CompositionAttachmentContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        CompositionAttachmentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> CompositionAttachmentContentConfiguration {
        self
    }
}
