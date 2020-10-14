// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

final public class CollectionItemsViewModel: ObservableObject {
    @Published public var alertItem: AlertItem?
    public private(set) var nextPageMaxId: String?

    private let items = CurrentValueSubject<[[CollectionItem]], Never>([])
    private let collectionService: CollectionService
    private let identification: Identification
    private var viewModelCache = [CollectionItem: (viewModel: CollectionItemViewModel, events: AnyCancellable)]()
    private let eventsSubject = PassthroughSubject<CollectionItemEvent, Never>()
    private let loadingSubject = PassthroughSubject<Bool, Never>()
    private let expandAllSubject: CurrentValueSubject<ExpandAllState, Never>
    private var maintainScrollPosition: CollectionItemIdentifier?
    private var topVisibleIndexPath = IndexPath(item: 0, section: 0)
    private var lastSelectedLoadMore: LoadMore?
    private var cancellables = Set<AnyCancellable>()

    public init(collectionService: CollectionService, identification: Identification) {
        self.collectionService = collectionService
        self.identification = identification
        expandAllSubject = CurrentValueSubject(
            collectionService is ContextService && !identification.identity.preferences.readingExpandSpoilers
                ? .expand : .hidden)

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
    public var updates: AnyPublisher<CollectionUpdate, Never> {
        items.map { [weak self] in
            CollectionUpdate(items: $0.map { $0.map(CollectionItemIdentifier.init(item:)) },
                             maintainScrollPosition: self?.maintainScrollPosition)
        }
        .eraseToAnyPublisher()
    }

    public var title: AnyPublisher<String, Never> { collectionService.title }

    public var expandAll: AnyPublisher<ExpandAllState, Never> {
        expandAllSubject.eraseToAnyPublisher()
    }

    public var alertItems: AnyPublisher<AlertItem, Never> { $alertItem.compactMap { $0 }.eraseToAnyPublisher() }

    public var loading: AnyPublisher<Bool, Never> { loadingSubject.eraseToAnyPublisher() }

    public var events: AnyPublisher<CollectionItemEvent, Never> { eventsSubject.eraseToAnyPublisher() }

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
            eventsSubject.send(
                .navigation(.collection(collectionService
                                            .navigationService
                                            .contextService(id: status.displayStatus.id))))
        case let .loadMore(loadMore):
            lastSelectedLoadMore = loadMore
            (viewModel(indexPath: indexPath) as? LoadMoreViewModel)?.loadMore()
        case let .account(account):
            eventsSubject.send(
                .navigation(.profile(collectionService
                                        .navigationService
                                        .profileService(account: account))))
        }
    }

    public func viewedAtTop(indexPath: IndexPath) {
        topVisibleIndexPath = indexPath
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
        let cachedViewModel = viewModelCache[item]?.viewModel

        switch item {
        case let .status(status, configuration):
            var viewModel: StatusViewModel

            if let cachedViewModel = cachedViewModel as? StatusViewModel {
                viewModel = cachedViewModel
            } else {
                viewModel = .init(
                    statusService: collectionService.navigationService.statusService(status: status),
                    identification: identification)
                cache(viewModel: viewModel, forItem: item)
            }

            viewModel.configuration = configuration

            return viewModel
        case let .loadMore(loadMore):
            if let cachedViewModel = cachedViewModel {
                return cachedViewModel
            }

            let viewModel = LoadMoreViewModel(
                loadMoreService: collectionService.navigationService.loadMoreService(loadMore: loadMore))

            cache(viewModel: viewModel, forItem: item)

            return viewModel
        case let .account(account):
            if let cachedViewModel = cachedViewModel {
                return cachedViewModel
            }

            let viewModel = AccountViewModel(
                accountService: collectionService.navigationService.accountService(account: account))

            cache(viewModel: viewModel, forItem: item)

            return viewModel
        }
    }

    public func toggleExpandAll() {
        let statusIds = Set(items.value.reduce([], +).compactMap { item -> Status.Id? in
            guard case let .status(status, _) = item else { return nil }

            return status.id
        })

        switch expandAllSubject.value {
        case .hidden:
            break
        case .expand:
            (collectionService as? ContextService)?.expand(ids: statusIds)
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .collect()
                .sink { [weak self] _ in self?.expandAllSubject.send(.collapse) }
                .store(in: &cancellables)
        case .collapse:
            (collectionService as? ContextService)?.collapse(ids: statusIds)
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .collect()
                .sink { [weak self] _ in self?.expandAllSubject.send(.expand) }
                .store(in: &cancellables)
        }
    }
}

private extension CollectionItemsViewModel {
    func cache(viewModel: CollectionItemViewModel, forItem item: CollectionItem) {
        viewModelCache[item] = (viewModel, viewModel.events.flatMap { $0 }
                                    .assignErrorsToAlertItem(to: \.alertItem, on: self)
                                    .sink { [weak self] in self?.eventsSubject.send($0) })
    }

    func process(items: [[CollectionItem]]) {
        maintainScrollPosition = identifierForScrollPositionMaintenance(newItems: items)
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
                       let direction = (viewModelCache[item]?.viewModel as? LoadMoreViewModel)?.direction,
                       direction == .up,
                       let statusAfterLoadMore = flatItems.first(where: {
                        guard case let .status(status, _) = $0 else { return false }

                        return status.id == loadMore.beforeStatusId
                       }) {
                        return .init(item: statusAfterLoadMore)
                    }
                }
            }

            if items.value.count > topVisibleIndexPath.section,
               items.value[topVisibleIndexPath.section].count > topVisibleIndexPath.item {
                let topVisibleItem = items.value[topVisibleIndexPath.section][topVisibleIndexPath.item]

                if newItems.count > topVisibleIndexPath.section,
                   let newIndex = newItems[topVisibleIndexPath.section].firstIndex(of: topVisibleItem),
                   newIndex > topVisibleIndexPath.item {
                    return .init(item: topVisibleItem)
                }
            }
        }

        return nil
    }
}
