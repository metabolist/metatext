// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class StatusTableViewCell: UITableViewCell {
    var viewModel: StatusViewModel?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let viewModel = viewModel else { return }

        contentConfiguration = StatusContentConfiguration(viewModel: viewModel).updated(for: state)
        accessibilityElements = [contentView]
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if viewModel?.configuration.hasReplyFollowing ?? false {
            separatorInset.right = .greatestFiniteMagnitude
        } else {
            separatorInset.right = UIDevice.current.userInterfaceIdiom == .phone ? 0 : layoutMargins.right
        }

        separatorInset.left = UIDevice.current.userInterfaceIdiom == .phone ? 0 : layoutMargins.left
    }
}
