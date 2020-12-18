// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class NewStatusDataSource: UICollectionViewDiffableDataSource<Int, CompositionViewModel.Id> {
    private let updateQueue =
        DispatchQueue(label: "com.metabolist.metatext.new-status-data-source.update-queue")

    init(collectionView: UICollectionView, viewModelProvider: @escaping (IndexPath) -> CompositionViewModel) {
        let registration = UICollectionView.CellRegistration<CompositionListCell, CompositionViewModel> {
            $0.viewModel = $2
        }

        super.init(collectionView: collectionView) { collectionView, indexPath, _ in
            collectionView.dequeueConfiguredReusableCell(
                using: registration,
                for: indexPath,
                item: viewModelProvider(indexPath))
        }
    }

    override func apply(_ snapshot: NSDiffableDataSourceSnapshot<Int, CompositionViewModel.Id>,
                        animatingDifferences: Bool = true,
                        completion: (() -> Void)? = nil) {
        updateQueue.async {
            super.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
        }
    }
}
