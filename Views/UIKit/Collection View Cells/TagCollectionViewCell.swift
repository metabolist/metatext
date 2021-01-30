// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class TagCollectionViewCell: UICollectionViewListCell {
    var viewModel: TagViewModel?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let viewModel = viewModel else { return }

        contentConfiguration = TagContentConfiguration(viewModel: viewModel).updated(for: state)
        updateConstraintsIfNeeded()
    }

    override func updateConstraints() {
        super.updateConstraints()

        let separatorLeadingAnchor: NSLayoutXAxisAnchor
        let separatorTrailingAnchor: NSLayoutXAxisAnchor

        if UIDevice.current.userInterfaceIdiom == .pad {
            separatorLeadingAnchor = readableContentGuide.leadingAnchor
            separatorTrailingAnchor = readableContentGuide.trailingAnchor
        } else {
            separatorLeadingAnchor = leadingAnchor
            separatorTrailingAnchor = trailingAnchor
        }

        NSLayoutConstraint.activate([
            separatorLayoutGuide.leadingAnchor.constraint(equalTo: separatorLeadingAnchor),
            separatorLayoutGuide.trailingAnchor.constraint(equalTo: separatorTrailingAnchor)
        ])
    }
}
