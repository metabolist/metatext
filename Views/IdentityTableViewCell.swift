// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class IdentityTableViewCell: UITableViewCell {
    var viewModel: IdentityViewModel?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let viewModel = viewModel else { return }

        contentConfiguration = IdentityContentConfiguration(viewModel: viewModel)
    }
}
