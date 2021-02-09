// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class TagTableViewCell: SeparatorConfiguredTableViewCell {
    var viewModel: TagViewModel?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let viewModel = viewModel else { return }

        contentConfiguration = TagContentConfiguration(viewModel: viewModel).updated(for: state)
    }
}
