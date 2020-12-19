// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import UIKit
import ViewModels

class CompositionAttachmentView: UIView {
    let imageView = UIImageView()
    private var compositionAttachmentConfiguration: CompositionAttachmentContentConfiguration

    init(configuration: CompositionAttachmentContentConfiguration) {
        self.compositionAttachmentConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyCompositionAttachmentConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CompositionAttachmentView: UIContentView {
    var configuration: UIContentConfiguration {
        get { compositionAttachmentConfiguration }
        set {
            guard let compositionAttachmentConfiguration = newValue as? CompositionAttachmentContentConfiguration
            else { return }

            self.compositionAttachmentConfiguration = compositionAttachmentConfiguration

            applyCompositionAttachmentConfiguration()
        }
    }
}

private extension CompositionAttachmentView {
    func initialSetup() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = .defaultCornerRadius
        imageView.clipsToBounds = true

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func applyCompositionAttachmentConfiguration() {
        imageView.kf.setImage(with: compositionAttachmentConfiguration.viewModel.attachment.previewUrl)
    }
}
