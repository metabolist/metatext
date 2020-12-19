// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

class CompositionAttachmentCollectionViewCell: UICollectionViewCell {
    var viewModel: CompositionAttachmentViewModel?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let viewModel = viewModel else { return }

        contentConfiguration = CompositionAttachmentContentConfiguration(viewModel: viewModel).updated(for: state)
        backgroundConfiguration = UIBackgroundConfiguration.clear().updated(for: state)
    }
}
