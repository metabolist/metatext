// Copyright © 2021 Metabolist. All rights reserved.

import BlurHash
import Combine
import SDWebImage
import UIKit
import ViewModels

final class EditThumbnailView: UIView {
    let playerView = PlayerView()
    let imageView = SDAnimatedImageView()
    let previewImageView = SDAnimatedImageView()
    let promptBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    let thumbnailPromptLabel = UILabel()

    private let viewModel: AttachmentViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var circleView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let circleView = UIVisualEffectView(effect: blurEffect)
        let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
        let scopeImageView = UIImageView(
            image: UIImage(systemName: "scope",
                           withConfiguration: UIImage.SymbolConfiguration(scale: .medium)))

        circleView.translatesAutoresizingMaskIntoConstraints = false
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false
        scopeImageView.translatesAutoresizingMaskIntoConstraints = false
        vibrancyView.contentView.addSubview(scopeImageView)
        circleView.contentView.addSubview(vibrancyView)
        circleView.layer.cornerRadius = .minimumButtonDimension / 2
        circleView.clipsToBounds = true
        scopeImageView.contentMode = .scaleAspectFit

        NSLayoutConstraint.activate([
            scopeImageView.centerXAnchor.constraint(equalTo: circleView.contentView.centerXAnchor),
            scopeImageView.centerYAnchor.constraint(equalTo: circleView.contentView.centerYAnchor),
            vibrancyView.leadingAnchor.constraint(equalTo: circleView.leadingAnchor),
            vibrancyView.topAnchor.constraint(equalTo: circleView.topAnchor),
            vibrancyView.trailingAnchor.constraint(equalTo: circleView.trailingAnchor),
            vibrancyView.bottomAnchor.constraint(equalTo: circleView.bottomAnchor),
            circleView.trailingAnchor.constraint(
                equalTo: scopeImageView.trailingAnchor, constant: .compactSpacing),
            circleView.bottomAnchor.constraint(
                equalTo: scopeImageView.bottomAnchor, constant: .compactSpacing),
            scopeImageView.topAnchor.constraint(
                equalTo: circleView.topAnchor, constant: .compactSpacing),
            scopeImageView.leadingAnchor.constraint(
                equalTo: circleView.leadingAnchor, constant: .compactSpacing),
            circleView.widthAnchor.constraint(equalToConstant: .minimumButtonDimension),
            circleView.heightAnchor.constraint(equalToConstant: .minimumButtonDimension)
        ])

        return circleView
    }()

    init(viewModel: AttachmentViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        guard let touch = touches.first else { return }

        if promptBackgroundView.effect != nil {
            UIView.animate(withDuration: .defaultAnimationDuration) {
                self.promptBackgroundView.effect = nil
                self.thumbnailPromptLabel.alpha = 0
            }
        }

        let location = touch.location(in: self)

        viewModel.editingFocus.x = Double(max(min(((location.x - (bounds.width / 2)) / (bounds.width / 2)), 1), -1))
        viewModel.editingFocus.y = Double(max(min((-location.y / (bounds.height / 2)) + 1, 1), -1))
    }
}

private extension EditThumbnailView {
    // swiftlint:disable:next function_body_length
    func initialSetup() {
        backgroundColor = .secondarySystemBackground

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.sd_imageIndicator = SDWebImageActivityIndicator.large

        addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(circleView)

        let circleViewCenterXConstraint = circleView.centerXAnchor.constraint(equalTo: centerXAnchor)
        let circleViewCenterYConstraint = circleView.centerYAnchor.constraint(equalTo: centerYAnchor)

        addSubview(promptBackgroundView)
        promptBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        if viewModel.editingFocus != .default {
            promptBackgroundView.effect = nil
        }

        promptBackgroundView.contentView.addSubview(thumbnailPromptLabel)
        thumbnailPromptLabel.translatesAutoresizingMaskIntoConstraints = false
        thumbnailPromptLabel.adjustsFontForContentSizeCategory = true
        thumbnailPromptLabel.font = .preferredFont(forTextStyle: .caption1)
        thumbnailPromptLabel.numberOfLines = 0
        thumbnailPromptLabel.textAlignment = .center
        thumbnailPromptLabel.text = NSLocalizedString("attachment.edit.thumbnail.prompt", comment: "")

        if viewModel.editingFocus != .default {
            thumbnailPromptLabel.alpha = 0
        }

        let previewImageContainerView = UIView()

        addSubview(previewImageContainerView)
        previewImageContainerView.translatesAutoresizingMaskIntoConstraints = false
        previewImageContainerView.layer.cornerRadius = .defaultCornerRadius
        previewImageContainerView.layer.shadowOffset = .zero
        previewImageContainerView.layer.shadowRadius = .defaultShadowRadius
        previewImageContainerView.layer.shadowOpacity = .defaultShadowOpacity

        previewImageContainerView.addSubview(previewImageView)
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.layer.cornerRadius = .defaultCornerRadius
        previewImageView.sd_setImage(with: viewModel.attachment.previewUrl?.url)

        switch viewModel.attachment.type {
        case .image:
            playerView.isHidden = true
            let placeholderImage: UIImage?

            if let blurHash = viewModel.attachment.blurhash {
                placeholderImage = UIImage(blurHash: blurHash, size: .blurHashSize)
            } else {
                placeholderImage = nil
            }

            imageView.sd_setImage(with: viewModel.attachment.previewUrl?.url, placeholderImage: placeholderImage)
        case .gifv:
            imageView.isHidden = true
            let player = PlayerCache.shared.player(url: viewModel.attachment.url.url)

            player.isMuted = true

            playerView.player = player
            player.play()
        default: break
        }

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            playerView.topAnchor.constraint(equalTo: topAnchor),
            playerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            circleViewCenterXConstraint,
            circleViewCenterYConstraint,
            promptBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            promptBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            promptBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            thumbnailPromptLabel.leadingAnchor.constraint(
                equalTo: promptBackgroundView.layoutMarginsGuide.leadingAnchor),
            thumbnailPromptLabel.topAnchor.constraint(equalTo: promptBackgroundView.layoutMarginsGuide.topAnchor),
            thumbnailPromptLabel.trailingAnchor.constraint(
                equalTo: promptBackgroundView.layoutMarginsGuide.trailingAnchor),
            thumbnailPromptLabel.bottomAnchor.constraint(equalTo: promptBackgroundView.layoutMarginsGuide.bottomAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: previewImageContainerView.leadingAnchor),
            previewImageView.topAnchor.constraint(equalTo: previewImageContainerView.topAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: previewImageContainerView.trailingAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: previewImageContainerView.bottomAnchor),
            previewImageContainerView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            previewImageContainerView.bottomAnchor.constraint(
                equalTo: layoutMarginsGuide.bottomAnchor,
                constant: -.defaultSpacing),
            previewImageContainerView.widthAnchor.constraint(
                equalTo: previewImageContainerView.heightAnchor,
                multiplier: 16 / 9),
            previewImageContainerView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1 / 8)
        ])

        viewModel.$editingFocus
            .receive(on: DispatchQueue.main) // punt to next run loop to allow initial layout to happen
            .sink { [weak self] in
                guard let self = self else { return }

                circleViewCenterXConstraint.constant = CGFloat($0.x) * self.bounds.width / 2
                circleViewCenterYConstraint.constant = -CGFloat($0.y) * self.bounds.height / 2

                guard let mediaSize = self.previewImageView.image?.size else { return }

                self.previewImageView.setContentsRect(focus: $0, mediaSize: mediaSize)
            }
            .store(in: &cancellables)
    }
}
