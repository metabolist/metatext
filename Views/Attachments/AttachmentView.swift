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
        imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        button.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        button.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true

        let highlightedButtonBackgroundImage = UIColor(white: 0, alpha: 0.5).image()

        button.setBackgroundImage(highlightedButtonBackgroundImage, for: .highlighted)

        switch viewModel.attachment.type {
        case .image:
            imageView.kf.setImage(with: viewModel.attachment.previewUrl)
        default:
            break
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
