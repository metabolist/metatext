// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

class LoadingTableFooterView: UIView {
    let activityIndicatorView = UIActivityIndicatorView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicatorView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        activityIndicatorView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        activityIndicatorView.startAnimating()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
