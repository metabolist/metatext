// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Kingfisher
import UIKit

class CompositionView: UIView {
    let avatarImageView = UIImageView()
    let textView = UITextView()
    let attachmentUploadView = AttachmentUploadView()
//    let attachmentsCollectionView = UICollectionView()

    private var compositionConfiguration: CompositionContentConfiguration
    private var cancellables = Set<AnyCancellable>()

    init(configuration: CompositionContentConfiguration) {
        self.compositionConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyCompositionConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CompositionView: UIContentView {
    var configuration: UIContentConfiguration {
        get { compositionConfiguration }
        set {
            guard let compositionConfiguration = newValue as? CompositionContentConfiguration else { return }

            self.compositionConfiguration = compositionConfiguration

            applyCompositionConfiguration()
        }
    }
}

extension CompositionView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        compositionConfiguration.viewModel.composition.text = textView.text
    }
}

private extension CompositionView {
    static let attachmentsCollectionViewHeight: CGFloat = 100

    func initialSetup() {
        addSubview(avatarImageView)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.layer.cornerRadius = .avatarDimension / 2
        avatarImageView.clipsToBounds = true

        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        stackView.addArrangedSubview(textView)
        textView.isScrollEnabled = false
        textView.adjustsFontForContentSizeCategory = true
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textContainer.lineFragmentPadding = 0
        textView.inputAccessoryView = CompositionInputAccessoryView(viewModel: compositionConfiguration.viewModel)
        textView.inputAccessoryView?.sizeToFit()
        textView.delegate = self

//        stackView.addArrangedSubview(attachmentsCollectionView)

        stackView.addArrangedSubview(attachmentUploadView)

        let constraints = [
            avatarImageView.heightAnchor.constraint(equalToConstant: .avatarDimension),
            avatarImageView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            avatarImageView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: readableContentGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: .defaultSpacing),
            stackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
//            attachmentsCollectionView.heightAnchor.constraint(equalToConstant: Self.attachmentsCollectionViewHeight)
            attachmentUploadView.heightAnchor.constraint(equalToConstant: Self.attachmentsCollectionViewHeight)
        ]

        for constraint in constraints {
            constraint.priority = .justBelowMax
        }

        NSLayoutConstraint.activate(constraints)

        compositionConfiguration.viewModel.$identification.map(\.identity.image)
            .sink { [weak self] in self?.avatarImageView.kf.setImage(with: $0) }
            .store(in: &cancellables)

        compositionConfiguration.viewModel.$attachmentUpload
            .sink { [weak self] in self?.attachmentUploadView.attachmentUpload = $0 }
            .store(in: &cancellables)
    }

    func applyCompositionConfiguration() {

    }
}
