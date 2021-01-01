// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit
import ViewModels

final class CompositionAttachmentsDataSource: UICollectionViewDiffableDataSource<Int, Attachment> {
    private let updateQueue =
        DispatchQueue(label: "com.metabolist.metatext.composition-attachments-data-source.update-queue")

    init(collectionView: UICollectionView,
         viewModelProvider: @escaping (IndexPath) -> CompositionAttachmentViewModel?) {
        let registration = UICollectionView.CellRegistration
        <CompositionAttachmentCollectionViewCell, CompositionAttachmentViewModel> {
            $0.viewModel = $2
        }

        super.init(collectionView: collectionView) { collectionView, indexPath, _ in
            collectionView.dequeueConfiguredReusableCell(
                using: registration,
                for: indexPath,
                item: viewModelProvider(indexPath))
        }
    }

    override func apply(_ snapshot: NSDiffableDataSourceSnapshot<Int, Attachment>,
                        animatingDifferences: Bool = true,
                        completion: (() -> Void)? = nil) {
        updateQueue.async {
            super.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
        }
    }
}
