// Copyright © 2020 Metabolist. All rights reserved.

import AVFoundation
import Combine
import Mastodon
import UIKit
import ViewModels

final class CompositionInputAccessoryView: UIView {
    let visibilityButton = UIButton()
    let addButton = UIButton()
    let contentWarningButton = UIButton(type: .system)

    private let viewModel: CompositionViewModel
    private let parentViewModel: NewStatusViewModel
    private let stackView = UIStackView()
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: CompositionViewModel, parentViewModel: NewStatusViewModel) {
        self.viewModel = viewModel
        self.parentViewModel = parentViewModel

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
    // swiftlint:disable:next function_body_length
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
        mediaButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }

            self.parentViewModel.presentMediaPicker(viewModel: self.viewModel)
        },
        for: .touchUpInside)

        #if !IS_SHARE_EXTENSION
        if AVCaptureDevice.authorizationStatus(for: .video) != .restricted {
            let cameraButton = UIButton()

            stackView.addArrangedSubview(cameraButton)
            cameraButton.setImage(
                UIImage(
                    systemName: "camera",
                    withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
                for: .normal)
            cameraButton.addAction(UIAction { [weak self] _ in
                guard let self = self else { return }

                self.parentViewModel.presentCamera(viewModel: self.viewModel)
            },
            for: .touchUpInside)
        }
        #endif

        let pollButton = UIButton()

        stackView.addArrangedSubview(pollButton)
        pollButton.setImage(
            UIImage(
                systemName: "chart.bar.xaxis",
                withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .normal)

        stackView.addArrangedSubview(visibilityButton)
        visibilityButton.showsMenuAsPrimaryAction = true
        visibilityButton.menu = UIMenu(children: Status.Visibility.allCasesExceptUnknown.reversed().map { visibility in
            UIAction(
                title: visibility.title ?? "",
                image: UIImage(systemName: visibility.systemImageName),
                discoverabilityTitle: visibility.description) { [weak self] _ in
                self?.parentViewModel.visibility = visibility
            }
        })

        stackView.addArrangedSubview(contentWarningButton)
        contentWarningButton.setTitle(
            NSLocalizedString("status.content-warning-abbreviation", comment: ""),
            for: .normal)
        contentWarningButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.displayContentWarning.toggle() },
            for: .touchUpInside)

        stackView.addArrangedSubview(UIView())

        stackView.addArrangedSubview(addButton)
        addButton.setImage(
            UIImage(
                systemName: "plus.circle.fill",
                withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .normal)
        addButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }

            self.parentViewModel.insert(after: self.viewModel)
        }, for: .touchUpInside)

        viewModel.$isPostable
            .sink { [weak self] in self?.addButton.isEnabled = $0 }
            .store(in: &cancellables)

        parentViewModel.$visibility
            .sink { [weak self] in
                self?.visibilityButton.setImage(UIImage(systemName: $0.systemImageName), for: .normal)
            }
            .store(in: &cancellables)

        for button in [mediaButton, pollButton, visibilityButton, contentWarningButton, addButton] {
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: .minimumButtonDimension).isActive = true
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: .minimumButtonDimension).isActive = true
        }

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
