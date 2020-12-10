// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class NewStatusDataSource: UICollectionViewDiffableDataSource<Int, Composition.Id> {
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
}
