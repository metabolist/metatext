// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class LoadMoreTableViewCell: SeparatorConfiguredTableViewCell {
    var viewModel: LoadMoreViewModel?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let viewModel = viewModel else { return }

        contentConfiguration = LoadMoreContentConfiguration(viewModel: viewModel)
        accessibilityElements = [contentView]
    }
}
