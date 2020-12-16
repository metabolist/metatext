// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

class CompositionInputAccessoryView: UIView {
    private let stackView = UIStackView()
    private let viewModel: CompositionViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: CompositionViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
}

private extension CompositionInputAccessoryView {
    func initialSetup() {
        autoresizingMask = .flexibleHeight
        backgroundColor = .secondarySystemFill

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = .defaultSpacing

        let mediaButton = UIButton()

        stackView.addArrangedSubview(mediaButton)
        mediaButton.setImage(
            UIImage(
                systemName: "photo",
                withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .normal)
        mediaButton.addAction(UIAction { [weak self] _ in self?.viewModel.presentMediaPicker() }, for: .touchUpInside)

        let pollButton = UIButton()

        stackView.addArrangedSubview(pollButton)
        pollButton.setImage(
            UIImage(
                systemName: "chart.bar.xaxis",
                withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .normal)

        stackView.addArrangedSubview(UIView())

        let addButton = UIButton()

        stackView.addArrangedSubview(addButton)
        addButton.setImage(
            UIImage(
                systemName: "plus.circle.fill",
                withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .normal)
        addButton.addAction(UIAction { [weak self] _ in self?.viewModel.insert() }, for: .touchUpInside)

        for button in [mediaButton, pollButton, addButton] {
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: .minimumButtonDimension).isActive = true
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: .minimumButtonDimension).isActive = true
        }

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        viewModel.$isPostable.sink { addButton.isEnabled = $0 }.store(in: &cancellables)
    }
}
