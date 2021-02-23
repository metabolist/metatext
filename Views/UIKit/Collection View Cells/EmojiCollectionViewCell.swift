// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class EmojiCollectionViewCell: UICollectionViewCell {
    var viewModel: EmojiViewModel?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let viewModel = viewModel else { return }

        contentConfiguration = EmojiContentConfiguration(viewModel: viewModel)

        var backgroundConfiguration = UIBackgroundConfiguration.listPlainCell().updated(for: state)

        if !state.isHighlighted && !state.isSelected {
            backgroundConfiguration.backgroundColor = .clear
        }

        backgroundConfiguration.cornerRadius = .defaultCornerRadius

        self.backgroundConfiguration = backgroundConfiguration
    }
}
