// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class ReportHeaderView: UIView {
    private let viewModel: ReportViewModel
    private let textView = UITextView()

    init(viewModel: ReportViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)

        initialSetup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ReportHeaderView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        viewModel.elements.comment = textView.text
    }
}

private extension ReportHeaderView {
    // swiftlint:disable:next function_body_length
    func initialSetup() {
        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .defaultSpacing

        let hintLabel = UILabel()

        stackView.addArrangedSubview(hintLabel)
        hintLabel.adjustsFontForContentSizeCategory = true
        hintLabel.font = .preferredFont(forTextStyle: .subheadline)
        hintLabel.text = NSLocalizedString("report.hint", comment: "")
        hintLabel.numberOfLines = 0

        stackView.addArrangedSubview(textView)
        textView.adjustsFontForContentSizeCategory = true
        textView.font = .preferredFont(forTextStyle: .body)
        textView.layer.borderWidth = .hairline
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.layer.cornerRadius = .defaultCornerRadius
        textView.delegate = self
        textView.accessibilityLabel = NSLocalizedString("report.additional-comments", comment: "")

        if !viewModel.isLocalAccount {
            let forwardHintLabel = UILabel()

            stackView.addArrangedSubview(forwardHintLabel)
            forwardHintLabel.adjustsFontForContentSizeCategory = true
            forwardHintLabel.font = .preferredFont(forTextStyle: .subheadline)
            forwardHintLabel.text = NSLocalizedString("report.forward.hint", comment: "")
            forwardHintLabel.numberOfLines = 0

            let switchStackView = UIStackView()

            stackView.addArrangedSubview(switchStackView)
            switchStackView.spacing = .defaultSpacing

            let switchLabel = UILabel()

            switchStackView.addArrangedSubview(switchLabel)
            switchLabel.adjustsFontForContentSizeCategory = true
            switchLabel.font = .preferredFont(forTextStyle: .headline)
            switchLabel.text = String.localizedStringWithFormat(
                NSLocalizedString("report.forward-%@", comment: ""),
                viewModel.accountHost)
            switchLabel.textAlignment = .right
            switchLabel.numberOfLines = 0

            let forwardSwitch = UISwitch()

            switchStackView.addArrangedSubview(forwardSwitch)
            forwardSwitch.setContentHuggingPriority(.required, for: .horizontal)
            forwardSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
            forwardSwitch.addAction(
                UIAction { [weak self] _ in self?.viewModel.elements.forward = forwardSwitch.isOn },
                for: .valueChanged)
        }

        let selectAdditionalHintLabel = UILabel()

        stackView.addArrangedSubview(selectAdditionalHintLabel)
        selectAdditionalHintLabel.adjustsFontForContentSizeCategory = true
        selectAdditionalHintLabel.font = .preferredFont(forTextStyle: .subheadline)
        selectAdditionalHintLabel.numberOfLines = 0

        switch viewModel.identityContext.appPreferences.statusWord {
        case .toot:
            selectAdditionalHintLabel.text = NSLocalizedString("report.select-additional.hint.toot", comment: "")
        case .post:
            selectAdditionalHintLabel.text = NSLocalizedString("report.select-additional.hint.post", comment: "")
        }

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
            textView.heightAnchor.constraint(equalToConstant: .minimumButtonDimension * 2)
        ])
    }
}
