// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class AttachmentsView: UIView {
    private let containerStackView = UIStackView()
    private let leftStackView = UIStackView()
    private let rightStackView = UIStackView()

    var attachmentViewModels = [AttachmentViewModel]() {
        didSet {
            for stackView in [leftStackView, rightStackView] {
                for view in stackView.arrangedSubviews {
                    stackView.removeArrangedSubview(view)
                    view.removeFromSuperview()
                }
            }

            let attachmentCount = attachmentViewModels.count

            rightStackView.isHidden = attachmentCount == 1

            for (index, viewModel) in attachmentViewModels.enumerated() {
                if attachmentCount == 2 && index == 1
                    || attachmentCount == 3 && index != 0
                    || attachmentCount > 3 && index % 2 != 0 {
                    rightStackView.addArrangedSubview(AttachmentView(viewModel: viewModel))
                } else {
                    leftStackView.addArrangedSubview(AttachmentView(viewModel: viewModel))
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        initializationActions()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        initializationActions()
    }
}

private extension AttachmentsView {

    func initializationActions() {
        backgroundColor = .clear
        layoutMargins = .zero
        clipsToBounds = true
        layer.cornerRadius = .defaultCornerRadius
        addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.distribution = .fillEqually
        containerStackView.spacing = .compactSpacing
        leftStackView.distribution = .fillEqually
        leftStackView.spacing = .compactSpacing
        leftStackView.axis = .vertical
        rightStackView.distribution = .fillEqually
        rightStackView.spacing = .compactSpacing
        rightStackView.axis = .vertical
        containerStackView.addArrangedSubview(leftStackView)
        containerStackView.addArrangedSubview(rightStackView)

        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            containerStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }
}
