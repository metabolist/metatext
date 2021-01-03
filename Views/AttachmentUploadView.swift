// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class AttachmentUploadView: UIView {
    let label = UILabel()
    let progressView = UIProgressView(progressViewStyle: .default)
    private var progressCancellable: AnyCancellable?

    var attachmentUpload: AttachmentUpload? {
        didSet {
            if let attachmentUpload = attachmentUpload {
                progressCancellable = attachmentUpload.progress.publisher(for: \.fractionCompleted)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.progressView.progress = Float($0) }
                isHidden = false
            } else {
                isHidden = true
            }
        }
    }

    init() {
        super.init(frame: .zero)

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .callout)
        label.textAlignment = .center
        label.text = NSLocalizedString("compose.attachment.uploading", comment: "")
        label.textColor = .secondaryLabel
        label.numberOfLines = 0

        addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            progressView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: .defaultSpacing),
            progressView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
