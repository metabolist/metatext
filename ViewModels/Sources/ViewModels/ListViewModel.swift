// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

final public class ListViewModel: ObservableObject {
    @Published public var alertItem: AlertItem?
    public private(set) var nextPageMaxID: String?
    public private(set) var maintainScrollPositionOfItem: CollectionItemIdentifier?

    private let items = CurrentValueSubject<[[CollectionItem]], Never>([])
    private let collectionService: CollectionService
    private var viewModelCache = [CollectionItem: (CollectionItemViewModel, AnyCancellable)]()
    private let navigationEventsSubject = PassthroughSubject<NavigationEvent, Never>()
    private let loadingSubject = PassthroughSubject<Bool, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(collectionService: CollectionService) {
        self.collectionService = collectionService

        collectionService.sections
            .handleEvents(receiveOutput: { [weak self] in self?.process(items: $0) })
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)

        collectionService.nextPageMaxIDs
            .sink { [weak self] in self?.nextPageMaxID = $0 }
            .store(in: &cancellables)
    }
}

extension ListViewModel: CollectionViewModel {
    public var sections: AnyPublisher<[[CollectionItemIdentifier]], Never> {
        items.map { $0.map { $0.map(CollectionItemIdentifier.init(item:)) } }.eraseToAnyPublisher()
    }

    public var title: AnyPublisher<String?, Never> { Just(collectionService.title).eraseToAnyPublisher() }

    public var alertItems: AnyPublisher<AlertItem, Never> { $alertItem.compactMap { $0 }.eraseToAnyPublisher() }

    public var loading: AnyPublisher<Bool, Never> { loadingSubject.eraseToAnyPublisher() }

    public var navigationEvents: AnyPublisher<NavigationEvent, Never> { navigationEventsSubject.eraseToAnyPublisher() }

    public func request(maxID: String? = nil, minID: String? = nil) {
        collectionService.request(maxID: maxID, minID: minID)
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
        case let .status(configuration):
            navigationEventsSubject.send(
                .collectionNavigation(
                    ListViewModel(
                        collectionService: collectionService
                            .navigationService
                            .contextService(id: configuration.status.displayStatus.id))))
        case .loadMore:
            (viewModel(indexPath: indexPath) as? LoadMoreViewModel)?.loadMore()
        case let .account(account):
            navigationEventsSubject.send(
                .profileNavigation(
                    ProfileViewModel(
                        profileService: collectionService.navigationService.profileService(account: account))))
        }
    }

    public func canSelect(indexPath: IndexPath) -> Bool {
        if case let .status(configuration) = items.value[indexPath.section][indexPath.item],
           configuration.status.id == collectionService.contextParentID {
            return false
        }

        return true
    }

    public func viewModel(indexPath: IndexPath) -> CollectionItemViewModel {
        let item = items.value[indexPath.section][indexPath.item]

        switch item {
        case let .status(configuration):
            var viewModel: StatusViewModel

            if let cachedViewModel = viewModelCache[item]?.0 as? StatusViewModel {
                viewModel = cachedViewModel
            } else {
                viewModel = StatusViewModel(
                    statusService: collectionService.navigationService.statusService(status: configuration.status))
                cache(viewModel: viewModel, forItem: item)
            }

            viewModel.isContextParent = configuration.status.id == collectionService.contextParentID
            viewModel.isPinned = configuration.pinned
            viewModel.isReplyInContext = configuration.isReplyInContext
            viewModel.hasReplyFollowing = configuration.hasReplyFollowing

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

private extension ListViewModel {
    func cache(viewModel: CollectionItemViewModel, forItem item: CollectionItem) {
        viewModelCache[item] = (viewModel, viewModel.events.flatMap { $0.compactMap(NavigationEvent.init) }
                                    .assignErrorsToAlertItem(to: \.alertItem, on: self)
                                    .sink { [weak self] in self?.navigationEventsSubject.send($0) })
    }

    func process(items: [[CollectionItem]]) {
        determineIfScrollPositionShouldBeMaintained(newItems: items)
        self.items.send(items)

        let itemsSet = Set(items.reduce([], +))

        viewModelCache = viewModelCache.filter { itemsSet.contains($0.key) }
    }

    func determineIfScrollPositionShouldBeMaintained(newItems: [[CollectionItem]]) {
        maintainScrollPositionOfItem = nil // clear old value

        // Maintain scroll position of parent after initial load of context
        if let contextParentID = collectionService.contextParentID {
            let contextParentIdentifier = CollectionItemIdentifier(id: contextParentID, kind: .status, info: [:])
            let onlyContextParentID = [[], [contextParentIdentifier], []]

            if items.value.isEmpty
                || items.value.map({ $0.map(CollectionItemIdentifier.init(item:)) }) == onlyContextParentID {
                maintainScrollPositionOfItem = contextParentIdentifier
            }
        }
    }
}
