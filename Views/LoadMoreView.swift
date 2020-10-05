// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import UIKit

final class LoadMoreView: UIView {
    private let leadingArrowImageView = UIImageView()
    private let trailingArrowImageView = UIImageView()
    private let label = UILabel()
    private let activityIndicatorView = UIActivityIndicatorView()
    private var loadMoreConfiguration: LoadMoreContentConfiguration
    private var loadingCancellable: AnyCancellable?
    private var directionChange = LoadMoreView.directionChangeMax

    init(configuration: LoadMoreContentConfiguration) {
        self.loadMoreConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyLoadMoreConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LoadMoreView {
    func directionChanged(up: Bool) {
        guard !loadMoreConfiguration.viewModel.loading else { return }

        if up, directionChange < Self.directionChangeMax {
            directionChange += Self.directionChangeIncrement
        } else if !up, directionChange > -Self.directionChangeMax {
            directionChange -= Self.directionChangeIncrement
        }

        updateDirectionChange(animated: false)
    }

    func finalizeDirectionChange() {
        directionChange = directionChange > 0 ? Self.directionChangeMax : -Self.directionChangeMax

        updateDirectionChange(animated: true)
    }
}

extension LoadMoreView: UIContentView {
    var configuration: UIContentConfiguration {
        get { loadMoreConfiguration }
        set {
            guard let loadMoreConfiguration = newValue as? LoadMoreContentConfiguration else { return }

            self.loadMoreConfiguration = loadMoreConfiguration

            applyLoadMoreConfiguration()
        }
    }
}

private extension LoadMoreView {
    static let directionChangeMax = CGFloat.pi
    static let directionChangeIncrement = CGFloat.pi / 10

    func initialSetup() {
        for arrowImageView in [leadingArrowImageView, trailingArrowImageView] {
            addSubview(arrowImageView)
            arrowImageView.translatesAutoresizingMaskIntoConstraints = false
            arrowImageView.image = UIImage(
                systemName: "arrow.up",
                withConfiguration: UIImage.SymbolConfiguration(
                    pointSize: UIFont.preferredFont(forTextStyle: .title2).pointSize))
            arrowImageView.setContentHuggingPriority(.required, for: .horizontal)
        }

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .title2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = label.tintColor
        label.text = NSLocalizedString("load-more", comment: "")
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)

        addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true

        NSLayoutConstraint.activate([
            leadingArrowImageView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            leadingArrowImageView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            leadingArrowImageView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: leadingArrowImageView.trailingAnchor),
            label.topAnchor.constraint(greaterThanOrEqualTo: readableContentGuide.topAnchor),
            label.bottomAnchor.constraint(greaterThanOrEqualTo: readableContentGuide.bottomAnchor),
            label.trailingAnchor.constraint(equalTo: trailingArrowImageView.leadingAnchor),
            trailingArrowImageView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            trailingArrowImageView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
            trailingArrowImageView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func applyLoadMoreConfiguration() {
        loadingCancellable = loadMoreConfiguration.viewModel.$loading.sink { [weak self] in
            guard let self = self else { return }

            self.label.isHidden = $0
            $0 ? self.activityIndicatorView.startAnimating() : self.activityIndicatorView.stopAnimating()
        }
    }

    func updateDirectionChange(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.1) {
                self.performDirectionChangeUpdates()
            }
        } else {
            self.performDirectionChangeUpdates()
        }
    }

    func performDirectionChangeUpdates() {
        loadMoreConfiguration.viewModel.direction = directionChange > 0 ? .up : .down
        leadingArrowImageView.transform = CGAffineTransform(rotationAngle: .pi / 2 - directionChange / 2)
        trailingArrowImageView.transform = CGAffineTransform(rotationAngle: -.pi / 2 + directionChange / 2)
    }
}
