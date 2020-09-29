// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import UIKit
import ViewModels

final class AttachmentView: UIView {
    let imageView = AnimatedImageView()
    let button = UIButton()
    let viewModel: AttachmentViewModel

    init(viewModel: AttachmentViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)

        layoutMargins = .zero
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(.highlightedButtonBackground, for: .highlighted)

        switch viewModel.attachment.type {
        case .image:
            imageView.kf.setImage(with: viewModel.attachment.previewUrl)
        default:
            break
        }

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            button.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            button.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
