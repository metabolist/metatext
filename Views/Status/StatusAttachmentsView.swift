// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class StatusAttachmentsView: UIView {
    private let containerStackView = UIStackView()
    private let leftStackView = UIStackView()
    private let rightStackView = UIStackView()
    private var aspectRatioConstraint: NSLayoutConstraint?

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
                let attachmentView = StatusAttachmentView(viewModel: viewModel)

                if attachmentCount == 2 && index == 1
                    || attachmentCount == 3 && index != 0
                    || attachmentCount > 3 && index % 2 != 0 {
                    rightStackView.addArrangedSubview(attachmentView)
                } else {
                    leftStackView.addArrangedSubview(attachmentView)
                }
            }

            let newAspectRatio: CGFloat

            if attachmentViewModels.count == 1, let aspectRatio = attachmentViewModels.first?.aspectRatio {
                newAspectRatio = max(CGFloat(aspectRatio), 16 / 9)
            } else {
                newAspectRatio = 16 / 9
            }

            aspectRatioConstraint?.isActive = false
            aspectRatioConstraint = widthAnchor.constraint(equalTo: heightAnchor, multiplier: newAspectRatio)
            aspectRatioConstraint?.priority = .justBelowMax
            aspectRatioConstraint?.isActive = true
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

private extension StatusAttachmentsView {
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
