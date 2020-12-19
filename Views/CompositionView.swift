// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Kingfisher
import UIKit

final class CompositionView: UIView {
    let avatarImageView = UIImageView()
    let textView = UITextView()
    let attachmentUploadView = AttachmentUploadView()
    let attachmentsCollectionView: UICollectionView

    private var compositionConfiguration: CompositionContentConfiguration
    private var cancellables = Set<AnyCancellable>()

    private lazy var attachmentsDataSource: CompositionAttachmentsDataSource = {
        CompositionAttachmentsDataSource(
            collectionView: attachmentsCollectionView,
            viewModelProvider: compositionConfiguration.viewModel.attachmentViewModel(indexPath:))
    }()

    init(configuration: CompositionContentConfiguration) {
        self.compositionConfiguration = configuration

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.2),
            heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(0.2))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item])

        group.interItemSpacing = .fixed(.defaultSpacing)

        let section = NSCollectionLayoutSection(group: group)
        let attachmentsLayout = UICollectionViewCompositionalLayout(section: section)
        attachmentsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: attachmentsLayout)

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
        compositionConfiguration.viewModel.text = textView.text
    }
}

private extension CompositionView {
    static let attachmentUploadViewHeight: CGFloat = 100

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

        stackView.addArrangedSubview(attachmentsCollectionView)
        attachmentsCollectionView.dataSource = attachmentsDataSource

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
            attachmentsCollectionView.heightAnchor.constraint(
                equalTo: attachmentsCollectionView.widthAnchor,
                multiplier: 1 / 4),
            attachmentUploadView.heightAnchor.constraint(equalToConstant: Self.attachmentUploadViewHeight)
        ]

        for constraint in constraints {
            constraint.priority = .justBelowMax
        }

        NSLayoutConstraint.activate(constraints)

        compositionConfiguration.viewModel.$identification.map(\.identity.image)
            .sink { [weak self] in self?.avatarImageView.kf.setImage(with: $0) }
            .store(in: &cancellables)

        compositionConfiguration.viewModel.$attachmentViewModels
            .sink { [weak self] in
                self?.attachmentsDataSource.apply([$0.map(\.attachment)].snapshot())
                self?.attachmentsCollectionView.isHidden = $0.isEmpty
            }
            .store(in: &cancellables)

        compositionConfiguration.viewModel.$attachmentUpload
            .sink { [weak self] in self?.attachmentUploadView.attachmentUpload = $0 }
            .store(in: &cancellables)
    }

    func applyCompositionConfiguration() {

    }
}
