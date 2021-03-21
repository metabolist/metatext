// Copyright © 2020 Metabolist. All rights reserved.

import AVKit
import BlurHash
import Combine
import SDWebImage
import UIKit
import ViewModels

final class AttachmentView: UIView {
    let playerView = PlayerView()
    let imageView = SDAnimatedImageView()
    let removeButton = UIButton(type: .close)
    let uncaptionedLabel = CapsuleLabel()
    let selectionButton = UIButton()

    var playing: Bool = false {
        didSet {
            if playing {
                play()
                imageView.tag = 0
                playerView.tag = viewModel.tag
            } else {
                stop()
                imageView.tag = viewModel.tag
                playerView.tag = 0
            }
        }
    }

    private let viewModel: AttachmentViewModel
    private let parentViewModel: AttachmentsRenderingViewModel
    private var playerCancellable: AnyCancellable?

    init(viewModel: AttachmentViewModel, parentViewModel: AttachmentsRenderingViewModel) {
        self.viewModel = viewModel
        self.parentViewModel = parentViewModel

        super.init(frame: .zero)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let focus = viewModel.attachment.meta?.focus {
            let viewsAndMediaSizes: [(UIView, CGSize?)] = [
                (imageView, imageView.image?.size),
                (playerView, playerView.player?.currentItem?.presentationSize)]
            for (view, mediaSize) in viewsAndMediaSizes {
                guard let size = mediaSize else { continue }

                view.setContentsRect(focus: focus, mediaSize: size)
            }
        }
    }
}

extension AttachmentView {
    func play() {
        let player = PlayerCache.shared.player(url: viewModel.attachment.url)

        playerCancellable = NotificationCenter.default.publisher(
            for: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem)
            .sink { _ in
                player.currentItem?.seek(to: .zero) { success in
                    guard success else { return }

                    player.play()
                }
        }

        player.isMuted = true
        player.play()
        playerView.player = player
        playerView.isHidden = false
    }

    func stop() {
        if let item = playerView.player?.currentItem {
            let imageGenerator = AVAssetImageGenerator(asset: item.asset)
            imageGenerator.requestedTimeToleranceAfter = .zero
            imageGenerator.requestedTimeToleranceBefore = .zero

            if let image = try? imageGenerator.copyCGImage(at: item.currentTime(), actualTime: nil) {
                imageView.image = .init(cgImage: image)
            }
        }

        playerView.player = nil
        playerView.isHidden = true
    }

    func selectAttachment() {
        parentViewModel.attachmentSelected(viewModel: viewModel)
    }
}

private extension AttachmentView {
    // swiftlint:disable:next function_body_length
    func initialSetup() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.autoPlayAnimatedImage = false
        imageView.tag = viewModel.tag

        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let playView = UIVisualEffectView(effect: blurEffect)
        let playVibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
        let playImageView = UIImageView(
            image: UIImage(systemName: "play.circle",
                           withConfiguration: UIImage.SymbolConfiguration(textStyle: .largeTitle)))

        playImageView.translatesAutoresizingMaskIntoConstraints = false
        playVibrancyView.translatesAutoresizingMaskIntoConstraints = false
        playVibrancyView.contentView.addSubview(playImageView)
        playView.contentView.addSubview(playVibrancyView)

        addSubview(playView)
        playView.translatesAutoresizingMaskIntoConstraints = false
        playView.clipsToBounds = true
        playView.layer.cornerRadius = .defaultCornerRadius
        playView.isHidden = viewModel.attachment.type == .image

        addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.videoGravity = .resizeAspectFill
        playerView.isHidden = true

        addSubview(selectionButton)
        selectionButton.translatesAutoresizingMaskIntoConstraints = false
        selectionButton.setBackgroundImage(.highlightedButtonBackground, for: .highlighted)
        selectionButton.addAction(
            UIAction { [weak self] _ in self?.selectAttachment() },
            for: .touchUpInside)
        selectionButton.accessibilityLabel = NSLocalizedString("compose.attachment.edit", comment: "")

        if let description = viewModel.attachment.description, !description.isEmpty {
            selectionButton.accessibilityLabel?.appendWithSeparator(description)
        }

        addSubview(removeButton)
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.showsMenuAsPrimaryAction = true
        removeButton.accessibilityLabel = NSLocalizedString("compose.attachment.remove", comment: "")
        removeButton.menu = UIMenu(
            children: [
                UIAction(
                    title: NSLocalizedString("remove", comment: ""),
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive) { [weak self] _ in
                    guard let self = self else { return }

                    self.parentViewModel.removeAttachment(viewModel: self.viewModel)
                }])

        addSubview(uncaptionedLabel)
        uncaptionedLabel.translatesAutoresizingMaskIntoConstraints = false
        uncaptionedLabel.text = NSLocalizedString("compose.attachment.uncaptioned", comment: "")
        uncaptionedLabel.isHidden = !(parentViewModel.canRemoveAttachments
                                        && (viewModel.attachment.description?.isEmpty ?? true))

        switch viewModel.attachment.type {
        case .image, .video, .gifv:
            let placeholderImage: UIImage?

            if let blurHash = viewModel.attachment.blurhash {
                placeholderImage = UIImage(blurHash: blurHash, size: .blurHashSize)
            } else {
                placeholderImage = nil
            }

            imageView.sd_setImage(
                with: viewModel.attachment.previewUrl,
                placeholderImage: placeholderImage) { [weak self] _, _, _, _ in
                self?.layoutSubviews()
            }
        case .audio:
            playImageView.image = UIImage(systemName: "waveform.circle",
                                          withConfiguration: UIImage.SymbolConfiguration(textStyle: .largeTitle))
            backgroundColor = .secondarySystemBackground
        case .unknown:
            playImageView.image = UIImage(systemName: "link",
                                          withConfiguration: UIImage.SymbolConfiguration(textStyle: .largeTitle))
            backgroundColor = .secondarySystemBackground
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
            playImageView.centerXAnchor.constraint(equalTo: playView.contentView.centerXAnchor),
            playImageView.centerYAnchor.constraint(equalTo: playView.contentView.centerYAnchor),
            playVibrancyView.leadingAnchor.constraint(equalTo: playView.leadingAnchor),
            playVibrancyView.topAnchor.constraint(equalTo: playView.topAnchor),
            playVibrancyView.trailingAnchor.constraint(equalTo: playView.trailingAnchor),
            playVibrancyView.bottomAnchor.constraint(equalTo: playView.bottomAnchor),
            playView.centerXAnchor.constraint(equalTo: centerXAnchor),
            playView.centerYAnchor.constraint(equalTo: centerYAnchor),
            playView.trailingAnchor.constraint(
                equalTo: playImageView.trailingAnchor, constant: .compactSpacing),
            playView.bottomAnchor.constraint(
                equalTo: playImageView.bottomAnchor, constant: .compactSpacing),
            playImageView.topAnchor.constraint(
                equalTo: playView.topAnchor, constant: .compactSpacing),
            playImageView.leadingAnchor.constraint(
                equalTo: playView.leadingAnchor, constant: .compactSpacing),
            selectionButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            selectionButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            selectionButton.topAnchor.constraint(equalTo: topAnchor),
            selectionButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            removeButton.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            removeButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            uncaptionedLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            uncaptionedLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])

        var accessibilityLabel = viewModel.attachment.type.accessibilityName

        if let description = viewModel.attachment.description {
            accessibilityLabel.appendWithSeparator(description)
        }

        self.accessibilityLabel = accessibilityLabel
    }
}
