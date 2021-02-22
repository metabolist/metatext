// Copyright © 2020 Metabolist. All rights reserved.

import AVFoundation
import Mastodon
import SDWebImage
import UIKit
import ViewModels

final class ImageViewController: UIViewController {
    let scrollView = UIScrollView()
    let imageView = SDAnimatedImageView()
    let playerView = PlayerView()

    private let viewModel: AttachmentViewModel?
    private let imageURL: URL?
    private let contentView = UIView()
    private let descriptionBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private let descriptionTextView = UITextView()

    init(viewModel: AttachmentViewModel? = nil, imageURL: URL? = nil) {
        self.viewModel = viewModel
        self.imageURL = imageURL

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // swiftlint:disable:next function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .secondarySystemBackground

        view.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.maximumZoomScale = Self.maximumZoomScale

        let doubleTapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleDoubleTap(gestureRecognizer:)))

        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGestureRecognizer)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.sd_imageIndicator = SDWebImageActivityIndicator.large
        imageView.autoPlayAnimatedImage = false

        contentView.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(descriptionBackgroundView)
        descriptionBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        descriptionBackgroundView.isHidden = viewModel?.attachment.description == nil
            || viewModel?.attachment.description == ""

        descriptionBackgroundView.contentView.addSubview(descriptionTextView)
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextView.backgroundColor = .clear
        descriptionTextView.font = .preferredFont(forTextStyle: .caption1)
        descriptionTextView.adjustsFontForContentSizeCategory = true
        descriptionTextView.text = viewModel?.attachment.description
        descriptionTextView.isScrollEnabled = false
        descriptionTextView.isEditable = false

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            playerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            playerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            descriptionBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            descriptionBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            descriptionBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            descriptionTextView.leadingAnchor.constraint(
                equalTo: descriptionBackgroundView.layoutMarginsGuide.leadingAnchor),
            descriptionTextView.topAnchor.constraint(equalTo: descriptionBackgroundView.topAnchor),
            descriptionTextView.trailingAnchor.constraint(
                equalTo: descriptionBackgroundView.layoutMarginsGuide.trailingAnchor),
            descriptionTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        if let viewModel = viewModel {
            switch viewModel.attachment.type {
            case .image:
                imageView.tag = viewModel.tag
                playerView.isHidden = true

                let placeholderKey = viewModel.attachment.previewUrl?.absoluteString
                let placeholderImage = SDImageCache.shared.imageFromCache(forKey: placeholderKey)

                imageView.sd_setImage(with: viewModel.attachment.url, placeholderImage: placeholderImage)
            case .gifv:
                playerView.tag = viewModel.tag
                imageView.isHidden = true
                let player = PlayerCache.shared.player(url: viewModel.attachment.url)

                player.isMuted = true

                playerView.player = player
                player.play()
            default: break
            }

            var accessibilityLabel = viewModel.attachment.type.accessibilityName

            if let description = viewModel.attachment.description {
                accessibilityLabel.appendWithSeparator(description)
            }
        } else if let imageURL = imageURL {
            imageView.tag = imageURL.hashValue
            playerView.isHidden = true
            imageView.sd_setImage(with: imageURL)
        }

        contentView.accessibilityLabel = viewModel?.attachment.type.accessibilityName
            ?? Attachment.AttachmentType.image.accessibilityName
        contentView.isAccessibilityElement = true
    }
}

extension ImageViewController {
    func toggleDescriptionVisibility() {
        UIView.animate(withDuration: .shortAnimationDuration) {
            self.descriptionBackgroundView.alpha = self.descriptionBackgroundView.alpha > 0 ? 0 : 1
        }
    }

    func presentActivityViewController() {
        if let image = imageView.image {
            let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: [])

            if UIDevice.current.userInterfaceIdiom == .pad {
                activityViewController.popoverPresentationController?
                    .barButtonItem = parent?.navigationItem.rightBarButtonItem
            }

            present(activityViewController, animated: true)
        } else if let asset = playerView.player?.currentItem?.asset as? AVURLAsset {
            asset.exportWithoutAudioTrack { result in
                DispatchQueue.main.async {
                    switch result {
                    case let .success(url):
                        let activityViewController = UIActivityViewController(
                            activityItems: [url],
                            applicationActivities: [])

                        if UIDevice.current.userInterfaceIdiom == .pad {
                            activityViewController.popoverPresentationController?
                                .barButtonItem = self.parent?.navigationItem.rightBarButtonItem
                        }

                        activityViewController.completionWithItemsHandler = { _, _, _, _ in
                            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
                        }

                        self.present(activityViewController, animated: true)
                    case .failure:
                        let alertController = UIAlertController(
                            title: nil,
                            message: NSLocalizedString("attachment.unable-to-export-media", comment: ""),
                            preferredStyle: .alert)

                        let okAction = UIAlertAction(
                            title: NSLocalizedString("ok", comment: ""),
                            style: .default) { _ in }

                        alertController.addAction(okAction)

                        self.present(alertController, animated: true)
                    }
                }
            }
        }
    }
}

extension ImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        contentView
    }

    // https://stackoverflow.com/a/40480610/2484482
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale > 1,
           let contentSize = imageView.image?.size ?? playerView.player?.currentItem?.presentationSize {
            let ratio = min(contentView.frame.width / contentSize.width, contentView.frame.height / contentSize.height)

            let newWidth = contentSize.width * ratio
            let newHeight = contentSize.height * ratio

            let horizontalInset = 0.5 * (newWidth * scrollView.zoomScale > contentView.frame.width
                                            ? (newWidth - contentView.frame.width)
                                            : (scrollView.frame.width - scrollView.contentSize.width))
            let verticalInset = 0.5 * (newHeight * scrollView.zoomScale > contentView.frame.height
                                        ? (newHeight - contentView.frame.height)
                                        : (scrollView.frame.height - scrollView.contentSize.height))

            scrollView.contentInset = .init(
                top: verticalInset,
                left: horizontalInset,
                bottom: verticalInset,
                right: horizontalInset)
        } else {
            scrollView.contentInset = .zero
        }
    }
}

private extension ImageViewController {
    static let maximumZoomScale: CGFloat = 4

    @objc func handleDoubleTap(gestureRecognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            let width = contentView.frame.size.width / scrollView.maximumZoomScale
            let height = contentView.frame.size.height / scrollView.maximumZoomScale
            let center = scrollView.convert(gestureRecognizer.location(in: gestureRecognizer.view), from: contentView)

            scrollView.zoom(
                to: CGRect(x: center.x - (width / 2), y: center.y - (height / 2), width: width, height: height),
                animated: true)
            } else {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            }
    }
}
