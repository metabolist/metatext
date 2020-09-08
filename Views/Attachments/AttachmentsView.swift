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
    static let spacing: CGFloat = 4
    static let cornerRadius: CGFloat = 8

    func initializationActions() {
        backgroundColor = .clear
        layoutMargins = .zero
        clipsToBounds = true
        layer.cornerRadius = Self.cornerRadius
        addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.distribution = .fillEqually
        containerStackView.spacing = Self.spacing
        containerStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        containerStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        containerStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        containerStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        leftStackView.distribution = .fillEqually
        leftStackView.spacing = Self.spacing
        leftStackView.axis = .vertical
        rightStackView.distribution = .fillEqually
        rightStackView.spacing = Self.spacing
        rightStackView.axis = .vertical
        containerStackView.addArrangedSubview(leftStackView)
        containerStackView.addArrangedSubview(rightStackView)
    }
}
