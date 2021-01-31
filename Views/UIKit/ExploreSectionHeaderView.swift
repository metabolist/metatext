// Copyright © 2021 Metabolist. All rights reserved.

import UIKit

final class ExploreSectionHeaderView: UICollectionReusableView {
    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ExploreSectionHeaderView {
    func initialSetup() {
        backgroundColor = .systemBackground

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .secondaryLabel

        let leadingConstraint: NSLayoutConstraint

        if UIDevice.current.userInterfaceIdiom == .pad {
            leadingConstraint = label.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1)
        } else {
            leadingConstraint = label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor)
        }

        NSLayoutConstraint.activate([
            leadingConstraint,
            label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }
}
