// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class AttachmentUploadView: UIView {
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

        addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            progressView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
