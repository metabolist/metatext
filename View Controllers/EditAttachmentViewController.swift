// Copyright © 2021 Metabolist. All rights reserved.

import AVKit
import Combine
import UIKit
import ViewModels

final class EditAttachmentViewController: UIViewController {
    private let viewModel: AttachmentViewModel
    private let parentViewModel: CompositionViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: AttachmentViewModel, parentViewModel: CompositionViewModel) {
        self.viewModel = viewModel
        self.parentViewModel = parentViewModel

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let playerViewController =
            children.first(where: { $0 is AVPlayerViewController }) as? AVPlayerViewController {
            playerViewController.player?.isMuted = true
            AVAudioSession.decrementPresentedPlayerViewControllerCount()
        }
    }

    // swiftlint:disable:next function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let trailingView: UIView

        switch viewModel.attachment.type {
        case .image, .gifv:
            trailingView = EditThumbnailView(viewModel: viewModel)
            view.addSubview(trailingView)
        default:
            let playerViewController = AVPlayerViewController()
            let player: AVPlayer

            if viewModel.attachment.type == .video {
                player = PlayerCache.shared.player(url: viewModel.attachment.url)
            } else {
                player = AVPlayer(url: viewModel.attachment.url)
            }

            player.isMuted = false
            playerViewController.player = player

            trailingView = playerViewController.view
            addChild(playerViewController)
            view.addSubview(trailingView)
            playerViewController.didMove(toParent: self)
            AVAudioSession.incrementPresentedPlayerViewControllerCount()
        }

        trailingView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView()

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .defaultSpacing

        let describeLabel = UILabel()

        stackView.addArrangedSubview(describeLabel)
        describeLabel.adjustsFontForContentSizeCategory = true
        describeLabel.font = .preferredFont(forTextStyle: .headline)
        describeLabel.numberOfLines = 0
        describeLabel.textAlignment = .center

        switch viewModel.attachment.type {
        case .audio:
            describeLabel.text = NSLocalizedString("attachment.edit.description.audio", comment: "")
        case .video:
            describeLabel.text = NSLocalizedString("attachment.edit.description.video", comment: "")
        default:
            describeLabel.text = NSLocalizedString("attachment.edit.description", comment: "")
        }

        let textView = UITextView()

        stackView.addArrangedSubview(textView)
        textView.adjustsFontForContentSizeCategory = true
        textView.font = .preferredFont(forTextStyle: .body)
        textView.layer.borderWidth = .hairline
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.layer.cornerRadius = .defaultCornerRadius
        textView.delegate = self
        textView.text = viewModel.editingDescription

        let remainingCharactersLabel = UILabel()

        stackView.addArrangedSubview(remainingCharactersLabel)
        remainingCharactersLabel.adjustsFontForContentSizeCategory = true
        remainingCharactersLabel.font = .preferredFont(forTextStyle: .subheadline)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: .defaultSpacing),
            trailingView.leadingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: .defaultSpacing),
            stackView.bottomAnchor.constraint(
                equalTo: view.layoutMarginsGuide.bottomAnchor,
                constant: -.defaultSpacing),
            trailingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            trailingView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            trailingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            trailingView.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 3 / 2)
        ])

        viewModel.$descriptionRemainingCharacters
            .sink {
                remainingCharactersLabel.text = String($0)
                remainingCharactersLabel.textColor = $0 < 0 ? .systemRed : .label
            }
            .store(in: &cancellables)

        textView.becomeFirstResponder()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        let cancelButton = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in
                self?.presentingViewController?.dismiss(animated: true)
            })
        let doneButton = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak self] _ in
                guard let self = self else { return }

                self.parentViewModel.update(attachmentViewModel: self.viewModel)
                self.presentingViewController?.dismiss(animated: true)
            })

        parent?.navigationItem.leftBarButtonItem = cancelButton
        parent?.navigationItem.rightBarButtonItem = doneButton
        parent?.navigationItem.title = NSLocalizedString("attachment.edit.title", comment: "")
    }
}

extension EditAttachmentViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        viewModel.editingDescription = textView.text
    }
}
