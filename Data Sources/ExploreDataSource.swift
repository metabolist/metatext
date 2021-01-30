// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import Mastodon
import UIKit
import ViewModels

final class ExploreDataSource: UICollectionViewDiffableDataSource<ExploreViewModel.Section, ExploreViewModel.Item> {
    private let updateQueue =
        DispatchQueue(label: "com.metabolist.metatext.explore-data-source.update-queue")
    private var cancellables = Set<AnyCancellable>()

    init(collectionView: UICollectionView, viewModel: ExploreViewModel) {
        let tagRegistration = UICollectionView.CellRegistration<TagCollectionViewCell, TagViewModel> {
            $0.viewModel = $2
        }

        super.init(collectionView: collectionView) {
            switch $2 {
            case let .tag(tag):
                return $0.dequeueConfiguredReusableCell(
                    using: tagRegistration,
                    for: $1,
                    item: viewModel.viewModel(tag: tag))
            }
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration
        <ExploreSectionHeaderView>(elementKind: "Header") { [weak self] in
            $0.label.text = self?.snapshot().sectionIdentifiers[$2.section].displayName
        }

        supplementaryViewProvider = {
            $0.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: $2)
        }

        viewModel.$trends.sink { [weak self] tags in
            guard let self = self else { return }

            var snapshot = NSDiffableDataSourceSnapshot<ExploreViewModel.Section, ExploreViewModel.Item>()

            if !tags.isEmpty {
                snapshot.appendSections([.trending])
                snapshot.appendItems(tags.map(ExploreViewModel.Item.tag), toSection: .trending)
            }

            self.apply(snapshot, animatingDifferences: false)
        }
        .store(in: &cancellables)
    }

    override func apply(_ snapshot: NSDiffableDataSourceSnapshot<ExploreViewModel.Section, ExploreViewModel.Item>,
                        animatingDifferences: Bool = true,
                        completion: (() -> Void)? = nil) {
        updateQueue.async {
            super.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
        }
    }
}

private extension ExploreViewModel.Section {
    var displayName: String {
        switch self {
        case .trending:
            return NSLocalizedString("explore.trending", comment: "")
        case .instance:
            return NSLocalizedString("explore.instance", comment: "")
        }
    }
}
