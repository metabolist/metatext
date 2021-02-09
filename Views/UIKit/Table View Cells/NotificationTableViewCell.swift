// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class NotificationTableViewCell: SeparatorConfiguredTableViewCell {
    var viewModel: NotificationViewModel?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let viewModel = viewModel else { return }

        contentConfiguration = NotificationContentConfiguration(viewModel: viewModel).updated(for: state)
        accessibilityElements = [contentView]
    }
}
