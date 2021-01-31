// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class InstanceCollectionViewCell: SeparatorConfiguredCollectionViewListCell {
    var viewModel: InstanceViewModel?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let viewModel = viewModel else { return }

        contentConfiguration = InstanceContentConfiguration(viewModel: viewModel).updated(for: state)
        updateConstraintsIfNeeded()
    }
}
