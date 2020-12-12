// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

class CompositionListCell: UICollectionViewListCell {
    var viewModel: CompositionViewModel?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let viewModel = viewModel else { return }

        contentConfiguration = CompositionContentConfiguration(viewModel: viewModel).updated(for: state)
        backgroundConfiguration = UIBackgroundConfiguration.clear().updated(for: state)
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                (contentView as? CompositionView)?.textView.becomeFirstResponder()
            }
        }
    }

    override func updateConstraints() {
        super.updateConstraints()

        separatorLayoutGuide.trailingAnchor.constraint(equalTo: separatorLayoutGuide.leadingAnchor).isActive = true
    }
}
