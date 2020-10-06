// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

final public class CollectionItemsViewModel: ObservableObject {
    @Published public var alertItem: AlertItem?
    public private(set) var nextPageMaxId: String?
    public private(set) var maintainScrollPositionOfItem: CollectionItemIdentifier?

    private let items = CurrentValueSubject<[[CollectionItem]], Never>([])
    private let collectionService: CollectionService
    private var viewModelCache = [CollectionItem: (CollectionItemViewModel, AnyCancellable)]()
    private let navigationEventsSubject = PassthroughSubject<NavigationEvent, Never>()
    private let loadingSubject = PassthroughSubject<Bool, Never>()
    private var lastSelectedLoadMore: LoadMore?
    private var cancellables = Set<AnyCancellable>()

    init(collectionService: CollectionService) {
        self.collectionService = collectionService

        collectionService.sections
            .handleEvents(receiveOutput: { [weak self] in self?.process(items: $0) })
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)

        collectionService.nextPageMaxId
            .sink { [weak self] in self?.nextPageMaxId = $0 }
            .store(in: &cancellables)
    }
}

extension CollectionItemsViewModel: CollectionViewModel {
    public var sections: AnyPublisher<[[CollectionItemIdentifier]], Never> {
        items.map { $0.map { $0.map(CollectionItemIdentifier.init(item:)) } }.eraseToAnyPublisher()
    }

    public var title: AnyPublisher<String, Never> { collectionService.title }

    public var alertItems: AnyPublisher<AlertItem, Never> { $alertItem.compactMap { $0 }.eraseToAnyPublisher() }

    public var loading: AnyPublisher<Bool, Never> { loadingSubject.eraseToAnyPublisher() }

    public var navigationEvents: AnyPublisher<NavigationEvent, Never> { navigationEventsSubject.eraseToAnyPublisher() }

    public func request(maxId: String? = nil, minId: String? = nil) {
        collectionService.request(maxId: maxId, minId: minId)
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.loadingSubject.send(true) },
                receiveCompletion: { [weak self] _ in self?.loadingSubject.send(false) })
            .sink { _ in }
            .store(in: &cancellables)
    }

    public func select(indexPath: IndexPath) {
        let item = items.value[indexPath.section][indexPath.item]

        switch item {
        case let .status(status, _):
            navigationEventsSubject.send(
                .collectionNavigation(
                    CollectionItemsViewModel(
                        collectionService: collectionService
                            .navigationService
                            .contextService(id: status.displayStatus.id))))
        case let .loadMore(loadMore):
            lastSelectedLoadMore = loadMore
            (viewModel(indexPath: indexPath) as? LoadMoreViewModel)?.loadMore()
        case let .account(account):
            navigationEventsSubject.send(
                .profileNavigation(
                    ProfileViewModel(
                        profileService: collectionService.navigationService.profileService(account: account))))
        }
    }

    public func canSelect(indexPath: IndexPath) -> Bool {
        switch items.value[indexPath.section][indexPath.item] {
        case let .status(_, configuration):
            return !configuration.isContextParent
        case .loadMore:
            return !((viewModel(indexPath: indexPath) as? LoadMoreViewModel)?.loading ?? false)
        default:
            return true
        }
    }

    public func viewModel(indexPath: IndexPath) -> CollectionItemViewModel {
        let item = items.value[indexPath.section][indexPath.item]

        switch item {
        case let .status(status, configuration):
            var viewModel: StatusViewModel

            if let cachedViewModel = viewModelCache[item]?.0 as? StatusViewModel {
                viewModel = cachedViewModel
            } else {
                viewModel = .init(statusService: collectionService.navigationService.statusService(status: status))
                cache(viewModel: viewModel, forItem: item)
            }

            viewModel.configuration = configuration

            return viewModel
        case let .loadMore(loadMore):
            if let cachedViewModel = viewModelCache[item]?.0 as? LoadMoreViewModel {
                return cachedViewModel
            }

            let viewModel = LoadMoreViewModel(
                loadMoreService: collectionService.navigationService.loadMoreService(loadMore: loadMore))

            cache(viewModel: viewModel, forItem: item)

            return viewModel
        case let .account(account):
            if let cachedViewModel = viewModelCache[item]?.0 as? AccountViewModel {
                return cachedViewModel
            }

            let viewModel = AccountViewModel(
                accountService: collectionService.navigationService.accountService(account: account))

            cache(viewModel: viewModel, forItem: item)

            return viewModel
        }
    }
}

private extension CollectionItemsViewModel {
    func cache(viewModel: CollectionItemViewModel, forItem item: CollectionItem) {
        viewModelCache[item] = (viewModel, viewModel.events.flatMap { $0.compactMap(NavigationEvent.init) }
                                    .assignErrorsToAlertItem(to: \.alertItem, on: self)
                                    .sink { [weak self] in self?.navigationEventsSubject.send($0) })
    }

    func process(items: [[CollectionItem]]) {
        maintainScrollPositionOfItem = identifierForScrollPositionMaintenance(newItems: items)
        self.items.send(items)

        let itemsSet = Set(items.reduce([], +))

        viewModelCache = viewModelCache.filter { itemsSet.contains($0.key) }
    }

    func identifierForScrollPositionMaintenance(newItems: [[CollectionItem]]) -> CollectionItemIdentifier? {
        let flatNewItems = newItems.reduce([], +)
        if collectionService is ContextService,
           items.value.isEmpty || items.value.map(\.count) == [0, 1, 0],
           let contextParent = flatNewItems.first(where: {
            guard case let .status(_, configuration) = $0 else { return false }

            return configuration.isContextParent // Maintain scroll position of parent after initial load of context
           }) {
            return .init(item: contextParent)
        } else if collectionService is TimelineService {
            let flatItems = items.value.reduce([], +)
            let difference = flatNewItems.difference(from: flatItems)

            if let lastSelectedLoadMore = lastSelectedLoadMore {
                for removal in difference.removals {
                    if case let .remove(_, item, _) = removal,
                       case let .loadMore(loadMore) = item,
                       loadMore == lastSelectedLoadMore,
                       let direction = (viewModelCache[item]?.0 as? LoadMoreViewModel)?.direction,
                       direction == .up,
                       let statusAfterLoadMore = flatItems.first(where: {
                        guard case let .status(status, _) = $0 else { return false }

                        return status.id == loadMore.beforeStatusId
                       }) {
                        return .init(item: statusAfterLoadMore)
                    }
                }
            }
        }

        return nil
    }
}
