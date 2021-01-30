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

        let layoutGuide: UILayoutGuide

        if UIDevice.current.userInterfaceIdiom == .pad {
            layoutGuide = readableContentGuide
        } else {
            layoutGuide = layoutMarginsGuide
        }

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            label.topAnchor.constraint(equalTo: layoutGuide.topAnchor),
            label.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
        ])
    }
}
