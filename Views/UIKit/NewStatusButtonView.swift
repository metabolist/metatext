// Copyright © 2021 Metabolist. All rights reserved.

import UIKit

final class NewStatusButtonView: UIView {
    let button: UIButton

    init(primaryAction: UIAction) {
        button = UIButton(type: .custom, primaryAction: primaryAction)

        super.init(frame: .zero)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension NewStatusButtonView {
    // swiftlint:disable:next function_body_length
    func initialSetup() {
        let blurEffect = UIBlurEffect(style: .systemChromeMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect, style: .label))

        backgroundColor = .clear
        layer.cornerRadius = .newStatusButtonDimension / 2
        layer.shadowPath = UIBezierPath(
            ovalIn: .init(
                origin: .zero,
                size: .init(
                    width: .newStatusButtonDimension,
                    height: .newStatusButtonDimension)))
            .cgPath
        layer.shadowOffset = .zero
        layer.shadowRadius = .defaultShadowRadius
        layer.shadowOpacity = 0.25

        addSubview(blurView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = .newStatusButtonDimension / 2
        blurView.clipsToBounds = true
        blurView.contentView.addSubview(vibrancyView)
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false

        let touchStartAction = UIAction { [weak self] _ in self?.alpha = 0.75 }

        button.translatesAutoresizingMaskIntoConstraints = false
        button.addAction(touchStartAction, for: .touchDown)
        button.addAction(touchStartAction, for: .touchDragEnter)

        let touchEndAction = UIAction { [weak self] _ in self?.alpha = 1 }

        button.addAction(touchEndAction, for: .touchDragExit)
        button.addAction(touchEndAction, for: .touchUpInside)
        button.addAction(touchEndAction, for: .touchUpOutside)
        button.addAction(touchEndAction, for: .touchCancel)

        button.setImage(
            UIImage(systemName: "pencil",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: .newStatusButtonDimension / 2)),
            for: .normal)
        vibrancyView.contentView.addSubview(button)

        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            vibrancyView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
            vibrancyView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
            vibrancyView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
            vibrancyView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: vibrancyView.contentView.leadingAnchor),
            button.topAnchor.constraint(equalTo: vibrancyView.contentView.topAnchor),
            button.trailingAnchor.constraint(equalTo: vibrancyView.contentView.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: vibrancyView.contentView.bottomAnchor)
        ])
    }
}
