// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

class WebfingerIndicatorView: UIVisualEffectView {
    private let activityIndicatorView = UIActivityIndicatorView()

    init() {
        super.init(effect: nil)

        clipsToBounds = true
        layer.cornerRadius = .defaultCornerRadius

        contentView.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.style = .large

        NSLayoutConstraint.activate([
        trailingAnchor.constraint(
            equalTo: activityIndicatorView.trailingAnchor, constant: .defaultSpacing),
        bottomAnchor.constraint(
            equalTo: activityIndicatorView.bottomAnchor, constant: .defaultSpacing),
        activityIndicatorView.topAnchor.constraint(
            equalTo: topAnchor, constant: .defaultSpacing),
        activityIndicatorView.leadingAnchor.constraint(
            equalTo: leadingAnchor, constant: .defaultSpacing),
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

        UIView.animate(withDuration: .defaultAnimationDuration) {
            self.effect = UIBlurEffect(style: .systemChromeMaterial)
        }
    }

    func stopAnimating() {
        activityIndicatorView.stopAnimating()

        UIView.animate(withDuration: .defaultAnimationDuration) {
            self.effect = nil
        } completion: { _ in
            self.isHidden = true
        }
    }
}
