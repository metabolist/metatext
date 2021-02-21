// Copyright © 2021 Metabolist. All rights reserved.

import UIKit

final class NewItemsView: UIView {
    let button = UIButton()

    public var title: String? {
        get { label.text }
        set {
            label.text = newValue
            button.accessibilityLabel = newValue
        }
    }

    private let label = UILabel()
    private let blurView: UIVisualEffectView
    private let vibrancyView: UIVisualEffectView

    init() {
        let blurEffect = UIBlurEffect(style: .systemChromeMaterial)
        blurView = UIVisualEffectView(effect: blurEffect)
        vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect, style: .label))

        super.init(frame: .zero)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let cornerRadius = bounds.height / 2

        layer.cornerRadius = cornerRadius
        blurView.layer.cornerRadius = cornerRadius
    }
}

private extension NewItemsView {
    // swiftlint:disable:next function_body_length
    func initialSetup() {
        backgroundColor = .clear
        layer.shadowOffset = .zero
        layer.shadowRadius = .defaultShadowRadius
        layer.shadowOpacity = .defaultShadowOpacity

        addSubview(blurView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.clipsToBounds = true
        blurView.contentView.addSubview(vibrancyView)
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView()

        vibrancyView.contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = .defaultSpacing

        let arrowImage = UIImage(systemName: "arrow.up",
                                 withConfiguration: UIImage.SymbolConfiguration(weight: .bold))

        stackView.addArrangedSubview(UIImageView(image: arrowImage))
        stackView.addArrangedSubview(label)
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .headline)

        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false

        let touchStartAction = UIAction { [weak self] _ in self?.alpha = 0.75 }

        button.addAction(touchStartAction, for: .touchDown)
        button.addAction(touchStartAction, for: .touchDragEnter)

        let touchEndAction = UIAction { [weak self] _ in self?.alpha = 1 }

        button.addAction(touchEndAction, for: .touchDragExit)
        button.addAction(touchEndAction, for: .touchUpInside)
        button.addAction(touchEndAction, for: .touchUpOutside)
        button.addAction(touchEndAction, for: .touchCancel)

        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            vibrancyView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
            vibrancyView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
            vibrancyView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
            vibrancyView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: vibrancyView.contentView.leadingAnchor,
                                               constant: .defaultSpacing),
            stackView.topAnchor.constraint(equalTo: vibrancyView.contentView.topAnchor, constant: .defaultSpacing),
            stackView.trailingAnchor.constraint(equalTo: vibrancyView.contentView.trailingAnchor,
                                                constant: -.defaultSpacing * 2),
            stackView.bottomAnchor.constraint(equalTo: vibrancyView.contentView.bottomAnchor,
                                              constant: -.defaultSpacing)
        ])
    }
}
