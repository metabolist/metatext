// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit
import ViewModels

final class CompositionAttachmentsDataSource: UICollectionViewDiffableDataSource<Int, Attachment> {
    private let updateQueue =
        DispatchQueue(label: "com.metabolist.metatext.composition-attachments-data-source.update-queue")

    init(collectionView: UICollectionView,
         viewModelProvider: @escaping (IndexPath) -> (CompositionAttachmentViewModel, CompositionViewModel)) {
        let registration = UICollectionView.CellRegistration
        <CompositionAttachmentCollectionViewCell, (CompositionAttachmentViewModel, CompositionViewModel)> {
            $0.viewModel = $2.0
            $0.parentViewModel = $2.1
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
