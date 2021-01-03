// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import UIKit
import ViewModels

class CompositionAttachmentView: UIView {
    let imageView = UIImageView()
    let removeButton = UIButton()
    let editButton = UIButton()
    private var compositionAttachmentConfiguration: CompositionAttachmentContentConfiguration
    private var aspectRatioConstraint: NSLayoutConstraint

    init(configuration: CompositionAttachmentContentConfiguration) {
        self.compositionAttachmentConfiguration = configuration

        aspectRatioConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 2)

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
    // swiftlint:disable:next function_body_length
    func initialSetup() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = .defaultCornerRadius
        clipsToBounds = true

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.kf.indicatorType = .activity

        addSubview(removeButton)
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.setImage(
            UIImage(
                systemName: "xmark.circle.fill",
                withConfiguration: UIImage.SymbolConfiguration(scale: .large)),
            for: .normal)
        removeButton.showsMenuAsPrimaryAction = true
        removeButton.menu = UIMenu(
            children: [
                UIAction(
                    title: NSLocalizedString("remove", comment: ""),
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive, handler: { [weak self] _ in
                        guard let self = self else { return }

                        self.compositionAttachmentConfiguration.parentViewModel.remove(
                            attachmentViewModel: self.compositionAttachmentConfiguration.viewModel)
                    })])

        addSubview(editButton)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.setImage(
            UIImage(
                systemName: "pencil.circle.fill",
                withConfiguration: UIImage.SymbolConfiguration(scale: .large)),
            for: .normal)
        editButton.addAction(UIAction { [weak self] _ in  }, for: .touchUpInside)

        NSLayoutConstraint.activate([
            aspectRatioConstraint,
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            removeButton.topAnchor.constraint(equalTo: topAnchor),
            removeButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            removeButton.heightAnchor.constraint(equalToConstant: .minimumButtonDimension),
            removeButton.widthAnchor.constraint(equalToConstant: .minimumButtonDimension),
            editButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            editButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            editButton.heightAnchor.constraint(equalToConstant: .minimumButtonDimension),
            editButton.widthAnchor.constraint(equalToConstant: .minimumButtonDimension)
        ])
    }

    func applyCompositionAttachmentConfiguration() {
        imageView.kf.setImage(with: compositionAttachmentConfiguration.viewModel.attachment.previewUrl)
        aspectRatioConstraint.isActive = false
        aspectRatioConstraint = imageView.widthAnchor.constraint(
            equalTo: imageView.heightAnchor,
            multiplier: CGFloat(compositionAttachmentConfiguration.viewModel.attachment.aspectRatio ?? 1))
        aspectRatioConstraint.priority = .justBelowMax
        aspectRatioConstraint.isActive = true
    }
}
