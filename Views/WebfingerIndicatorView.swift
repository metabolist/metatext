// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

class WebfingerIndicatorView: UIVisualEffectView {
    private let activityIndicatorView = UIActivityIndicatorView()

    init() {
        super.init(effect: nil)

        clipsToBounds = true
        layer.cornerRadius = 8

        contentView.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.style = .large

        NSLayoutConstraint.activate([
        trailingAnchor.constraint(
            equalTo: activityIndicatorView.trailingAnchor, constant: 8),
        bottomAnchor.constraint(
            equalTo: activityIndicatorView.bottomAnchor, constant: 8),
        activityIndicatorView.topAnchor.constraint(
            equalTo: topAnchor, constant: 8),
        activityIndicatorView.leadingAnchor.constraint(
            equalTo: leadingAnchor, constant: 8),
        activityIndicatorView.centerXAnchor.constraint(
            equalTo: contentView.safeAreaLayoutGuide.centerXAnchor),
        activityIndicatorView.centerYAnchor.constraint(
            equalTo: contentView.safeAreaLayoutGuide.centerYAnchor)
        ])

        isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WebfingerIndicatorView {
    func startAnimating() {
        isHidden = false
        activityIndicatorView.startAnimating()

        UIView.animate(withDuration: 0.5) {
            self.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        }
    }

    func stopAnimating() {
        activityIndicatorView.stopAnimating()

        UIView.animate(withDuration: 0.5) {
            self.effect = nil
        } completion: { _ in
            self.isHidden = true
        }
    }
}
