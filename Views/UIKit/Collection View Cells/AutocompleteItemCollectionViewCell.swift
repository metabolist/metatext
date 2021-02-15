// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class AutocompleteItemCollectionViewCell: SeparatorConfiguredCollectionViewListCell {
    var item: AutocompleteItem?
    var identityContext: IdentityContext?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let item = item, let identityContext = identityContext else { return }

        contentConfiguration = AutocompleteItemContentConfiguration(item: item, identityContext: identityContext)

        var backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()

        backgroundConfiguration.backgroundColor = state.isHighlighted || state.isSelected ? nil : .clear

        self.backgroundConfiguration = backgroundConfiguration

        accessibilityElements = [contentView]
    }
}
