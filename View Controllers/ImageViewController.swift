// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import UIKit
import ViewModels

class ImageViewController: UIViewController {
    private let viewModel: AttachmentViewModel
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let imageView = AnimatedImageView()
    private let playerView = PlayerView()
    private let descriptionBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private let descriptionTextView = UITextView()

    init(viewModel: AttachmentViewModel) {
        self.viewModel = viewModel

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

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        contentView.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(descriptionBackgroundView)
        descriptionBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        descriptionBackgroundView.isHidden = viewModel.attachment.description == nil
            || viewModel.attachment.description == ""

        descriptionBackgroundView.contentView.addSubview(descriptionTextView)
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextView.backgroundColor = .clear
        descriptionTextView.font = .preferredFont(forTextStyle: .caption1)
        descriptionTextView.adjustsFontForContentSizeCategory = true
        descriptionTextView.text = viewModel.attachment.description
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

        switch viewModel.attachment.type {
        case .image:
            playerView.isHidden = true
            imageView.isHidden = false
            imageView.kf.indicatorType = .activity
            imageView.kf.setImage(
                with: viewModel.attachment.previewUrl,
                options: [.onlyFromCache],
                completionHandler: { [weak self] in
                guard let self = self else { return }

                if case .success = $0 {
                    self.imageView.kf.indicatorType = .none
                }

                self.imageView.kf.setImage(
                    with: self.viewModel.attachment.url,
                    options: [.keepCurrentImageWhileLoading])
            })
        case .gifv:
            playerView.isHidden = false
            imageView.isHidden = true
            let player = PlayerCache.shared.player(url: viewModel.attachment.url)

            player.isMuted = true

            playerView.player = player
            player.play()
        default: break
        }
    }
}

extension ImageViewController {
    func toggleDescriptionVisibility() {
        UIView.animate(withDuration: .shortAnimationDuration) {
            self.descriptionBackgroundView.alpha = self.descriptionBackgroundView.alpha > 0 ? 0 : 1
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
    static let maximumZoomScale: CGFloat = 5
}
