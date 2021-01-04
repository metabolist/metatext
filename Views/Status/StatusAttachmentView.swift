// Copyright © 2020 Metabolist. All rights reserved.

import AVKit
import Kingfisher
import UIKit
import ViewModels

final class StatusAttachmentView: UIView {
    let playerView = PlayerView()
    let imageView = AnimatedImageView()
    let button = UIButton()

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
    private var playerLooper: AVPlayerLooper?

    init(viewModel: AttachmentViewModel) {
        self.viewModel = viewModel

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
            let viewsAndSizes: [(UIView, CGSize?)] = [
                (imageView, imageView.image?.size),
                (playerView, playerView.player?.currentItem?.presentationSize)]
            for (view, size) in viewsAndSizes {
                guard let size = size else { continue }

                let aspectRatio = size.width / size.height
                let viewAspectRatio = view.frame.width / view.frame.height
                var origin = CGPoint.zero

                if viewAspectRatio > aspectRatio {
                    let mediaProportionalHeight = size.height * view.frame.width / size.width
                    let maxPan = (mediaProportionalHeight - view.frame.height) / (2 * mediaProportionalHeight)

                    origin.y = CGFloat(-focus.y) * maxPan
                } else {
                    let mediaProportionalWidth = size.width * view.frame.height / size.height
                    let maxPan = (mediaProportionalWidth - view.frame.width) / (2 * mediaProportionalWidth)

                    origin.x = CGFloat(focus.x) * maxPan
                }

                view.layer.contentsRect = .init(origin: origin, size: CGRect.defaultContentsRect.size)
            }
        }
    }
}

extension StatusAttachmentView {
    func play() {
        let player = PlayerCache.shared.player(url: viewModel.attachment.url)

        if let cachedPlayerLooper = Self.playerLooperCache[player] {
            playerLooper = cachedPlayerLooper
        } else if let item = player.currentItem {
            playerLooper = AVPlayerLooper(player: player, templateItem: item)
            Self.playerLooperCache[player] = playerLooper
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
}

private extension StatusAttachmentView {
    static var playerLooperCache = [AVQueuePlayer: AVPlayerLooper]()

    // swiftlint:disable:next function_body_length
    func initialSetup() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
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

        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(.highlightedButtonBackground, for: .highlighted)

        switch viewModel.attachment.type {
        case .image, .video, .gifv:
            imageView.kf.setImage(
                with: viewModel.attachment.previewUrl,
                completionHandler: { [weak self] _ in
                    self?.layoutSubviews()
                })
        case .audio:
            playImageView.image = UIImage(systemName: "waveform.circle",
                                          withConfiguration: UIImage.SymbolConfiguration(textStyle: .largeTitle))
            backgroundColor = .secondarySystemBackground
        default:
            break
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
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
