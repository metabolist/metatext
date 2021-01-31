// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import Mastodon
import UIKit
import ViewModels

final class ExploreDataSource: UICollectionViewDiffableDataSource<ExploreViewModel.Section, ExploreViewModel.Item> {
    private let updateQueue =
        DispatchQueue(label: "com.metabolist.metatext.explore-data-source.update-queue")
    private weak var collectionView: UICollectionView?
    private var cancellables = Set<AnyCancellable>()

    init(collectionView: UICollectionView, viewModel: ExploreViewModel) {
        self.collectionView = collectionView

        super.init(collectionView: collectionView) {
            switch $2 {
            case let .tag(tag):
                return $0.dequeueConfiguredReusableCell(
                    using: Self.tagRegistration,
                    for: $1,
                    item: viewModel.viewModel(tag: tag))
            case .instance:
                return $0.dequeueConfiguredReusableCell(
                    using: Self.instanceRegistration,
                    for: $1,
                    item: viewModel.instanceViewModel)
            default:
                return $0.dequeueConfiguredReusableCell(using: Self.itemRegistration, for: $1, item: $2)
            }
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration
        <ExploreSectionHeaderView>(elementKind: "Header") { [weak self] in
            $0.label.text = self?.snapshot().sectionIdentifiers[$2.section].displayName
        }

        supplementaryViewProvider = {
            $0.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: $2)
        }

        viewModel.$trends.combineLatest(viewModel.$instanceViewModel)
            .sink { [weak self] in self?.update(tags: $0, instanceViewModel: $1) }
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

private extension ExploreDataSource {
    static let tagRegistration = UICollectionView.CellRegistration<TagCollectionViewCell, TagViewModel> {
        $0.viewModel = $2
    }

    static let instanceRegistration = UICollectionView.CellRegistration<InstanceCollectionViewCell, InstanceViewModel> {
        $0.viewModel = $2
    }

    static let itemRegistration = UICollectionView.CellRegistration
    <SeparatorConfiguredCollectionViewListCell, ExploreViewModel.Item> {
        var configuration = $0.defaultContentConfiguration()

        switch $2 {
        case .profileDirectory:
            configuration.text = NSLocalizedString("explore.profile-directory", comment: "")
            configuration.image = UIImage(systemName: "person.crop.square.fill.and.at.rectangle")
        default:
            break
        }

        $0.contentConfiguration = configuration
        $0.accessories = [.disclosureIndicator()]
    }

    func update(tags: [Tag], instanceViewModel: InstanceViewModel?) {
        var newsnapshot = NSDiffableDataSourceSnapshot<ExploreViewModel.Section, ExploreViewModel.Item>()

        if !tags.isEmpty {
            newsnapshot.appendSections([.trending])
            newsnapshot.appendItems(tags.map(ExploreViewModel.Item.tag), toSection: .trending)
        }

        if let instanceViewModel = instanceViewModel {
            newsnapshot.appendSections([.instance])
            newsnapshot.appendItems([.instance], toSection: .instance)

            if instanceViewModel.instance.canShowProfileDirectory {
                newsnapshot.appendItems([.profileDirectory], toSection: .instance)
            }
        }

        let wasEmpty = self.snapshot().itemIdentifiers.isEmpty
        let contentOffset = collectionView?.contentOffset

        apply(newsnapshot, animatingDifferences: false) {
            if let contentOffset = contentOffset, !wasEmpty {
                self.collectionView?.contentOffset = contentOffset
            }
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
