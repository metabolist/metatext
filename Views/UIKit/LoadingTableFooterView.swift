// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

final class LoadingTableFooterView: UIView {
    let activityIndicatorView = UIActivityIndicatorView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.style = .large

        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            activityIndicatorView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])

        activityIndicatorView.startAnimating()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
