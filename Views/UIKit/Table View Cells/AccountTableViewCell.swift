// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class AccountTableViewCell: SeparatorConfiguredTableViewCell {
    var viewModel: AccountViewModel?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let viewModel = viewModel else { return }

        contentConfiguration = AccountContentConfiguration(viewModel: viewModel).updated(for: state)
        accessibilityElements = [contentView]
    }
}
