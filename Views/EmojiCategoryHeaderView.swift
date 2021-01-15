// Copyright © 2021 Metabolist. All rights reserved.

import UIKit

final class EmojiCategoryHeaderView: UICollectionReusableView {
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

private extension EmojiCategoryHeaderView {
    func initialSetup() {
        backgroundColor = .clear

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .secondaryLabel

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }
}
