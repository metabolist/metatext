// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class MarkAttachmentsSensitiveView: UIView {
    private let label = UILabel()
    private let sensitiveSwitch = UISwitch()
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
}

private extension MarkAttachmentsSensitiveView {
    func initialSetup() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .callout)
        label.textColor = .secondaryLabel
        label.text = NSLocalizedString("compose.mark-media-sensitive", comment: "")
        label.textAlignment = .right

        addSubview(sensitiveSwitch)
        sensitiveSwitch.translatesAutoresizingMaskIntoConstraints = false
        sensitiveSwitch.addAction(
            UIAction { [weak self] _ in
                guard let self = self else { return }

                self.viewModel.sensitive = self.sensitiveSwitch.isOn
            },
            for: .valueChanged)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            label.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            sensitiveSwitch.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: .defaultSpacing),
            sensitiveSwitch.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            sensitiveSwitch.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            sensitiveSwitch.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])

        viewModel.$sensitive
            .sink { [weak self] in self?.sensitiveSwitch.setOn($0, animated: true) }
            .store(in: &cancellables)
        viewModel.$displayContentWarning
            .sink { [weak self] in self?.sensitiveSwitch.isEnabled = !$0 }
            .store(in: &cancellables)
    }
}
