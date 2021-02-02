// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class AttachmentUploadView: UIView {
    let label = UILabel()
    let cancelButton = UIButton(type: .system)
    let progressView = UIProgressView(progressViewStyle: .default)

    private let viewModel: CompositionViewModel
    private var progressCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    // swiftlint:disable:next function_body_length
    init(viewModel: CompositionViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .callout)
        label.textAlignment = .center
        label.text = NSLocalizedString("compose.attachment.uploading", comment: "")
        label.textColor = .secondaryLabel
        label.numberOfLines = 0

        addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.titleLabel?.adjustsFontForContentSizeCategory = true
        cancelButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        cancelButton.setTitle(NSLocalizedString("cancel", comment: ""), for: .normal)
        cancelButton.addAction(UIAction { _ in viewModel.cancelUpload() }, for: .touchUpInside)
        cancelButton.accessibilityLabel =
            NSLocalizedString("compose.attachment.cancel-upload.accessibility-label", comment: "")

        addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            label.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: .defaultSpacing),
            cancelButton.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: label.bottomAnchor),
            progressView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: .defaultSpacing),
            progressView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])

        viewModel.$attachmentUpload.sink { [weak self] attachmentUpload in
            guard let self = self else { return }

            UIView.animate(withDuration: .zeroIfReduceMotion(.shortAnimationDuration)) {
                if let attachmentUpload = attachmentUpload {
                    self.progressCancellable = attachmentUpload.progress.publisher(for: \.fractionCompleted)
                        .receive(on: DispatchQueue.main)
                        .sink { self.progressView.progress = Float($0) }
                    self.isHidden = false
                } else {
                    self.isHidden = true
                }
            }
        }
        .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
