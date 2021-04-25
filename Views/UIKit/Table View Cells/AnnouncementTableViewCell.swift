// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class AnnouncementTableViewCell: SeparatorConfiguredTableViewCell {
    var viewModel: AnnouncementViewModel?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let viewModel = viewModel else { return }

        contentConfiguration = AnnouncementContentConfiguration(viewModel: viewModel).updated(for: state)
        accessibilityElements = [contentView]
    }
}
