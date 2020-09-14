// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

class StatusListCell: UITableViewCell {
    var viewModel: StatusViewModel?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let viewModel = viewModel else { return }

        contentConfiguration = StatusContentConfiguration(viewModel: viewModel).updated(for: state)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        separatorInset.left = UIDevice.current.userInterfaceIdiom == .phone ? 0 : layoutMargins.left
    }
}
