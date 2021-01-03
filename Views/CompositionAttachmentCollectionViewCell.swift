// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

class CompositionAttachmentCollectionViewCell: UICollectionViewCell {
    var viewModel: CompositionAttachmentViewModel?
    var parentViewModel: CompositionViewModel?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let viewModel = viewModel, let parentViewModel = parentViewModel else { return }

        contentConfiguration = CompositionAttachmentContentConfiguration(
            viewModel: viewModel,
            parentViewModel: parentViewModel)
            .updated(for: state)
        backgroundConfiguration = UIBackgroundConfiguration.clear().updated(for: state)
    }
}
