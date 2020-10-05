// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

final public class ListViewModel: ObservableObject {
    @Published public private(set) var identifiers = [[CollectionItemIdentifier]]()
    @Published public var alertItem: AlertItem?
    public private(set) var nextPageMaxID: String?
    public private(set) var maintainScrollPositionOfItem: CollectionItemIdentifier?

    private var items = [CollectionItemIdentifier: CollectionItem]()
    private let collectionService: CollectionService
    private var viewModelCache = [CollectionItem: (CollectionItemViewModel, AnyCancellable)]()
    private let navigationEventsSubject = PassthroughSubject<NavigationEvent, Never>()
    private let loadingSubject = PassthroughSubject<Bool, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(collectionService: CollectionService) {
        self.collectionService = collectionService

        collectionService.sections
            .handleEvents(receiveOutput: { [weak self] in self?.process(sections: $0) })
            .map { $0.map { $0.map(CollectionItemIdentifier.init(item:)) } }
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$identifiers)

        collectionService.nextPageMaxIDs
            .sink { [weak self] in self?.nextPageMaxID = $0 }
            .store(in: &cancellables)
    }
}

extension ListViewModel: CollectionViewModel {
    public var sections: AnyPublisher<[[CollectionItemIdentifier]], Never> { $identifiers.eraseToAnyPublisher() }

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

    public func select(identifier: CollectionItemIdentifier) {
        guard let item = items[identifier] else { return }

        switch item {
        case let .status(configuration):
            navigationEventsSubject.send(
                .collectionNavigation(
                    ListViewModel(
                        collectionService: collectionService
                            .navigationService
                            .contextStatusListService(id: configuration.status.displayStatus.id))))
        case .loadMore:
            loadMoreViewModel(item: identifier)?.loadMore()
        case let .account(account):
            navigationEventsSubject.send(
                .profileNavigation(
                    ProfileViewModel(
                        profileService: collectionService.navigationService.profileService(account: account))))
        }
    }

    public func canSelect(identifier: CollectionItemIdentifier) -> Bool {
        if case .status = identifier.kind, identifier.id == collectionService.contextParentID {
            return false
        }

        return true
    }

    public func viewModel(identifier: CollectionItemIdentifier) -> CollectionItemViewModel? {
        switch identifier.kind {
        case .status:
            return statusViewModel(item: identifier)
        case .loadMore:
            return loadMoreViewModel(item: identifier)
        case .account:
            return accountViewModel(item: identifier)
        }
    }
}

private extension ListViewModel {
    func statusViewModel(item: CollectionItemIdentifier) -> StatusViewModel? {
        guard let timelineItem = items[item],
              case let .status(configuration) = timelineItem
        else { return nil }

        var statusViewModel: StatusViewModel

        if let cachedViewModel = viewModelCache[timelineItem]?.0 as? StatusViewModel {
            statusViewModel = cachedViewModel
        } else {
            statusViewModel = StatusViewModel(
                statusService: collectionService.navigationService.statusService(status: configuration.status))
            cache(viewModel: statusViewModel, forItem: timelineItem)
        }

        statusViewModel.isContextParent = configuration.status.id == collectionService.contextParentID
        statusViewModel.isPinned = configuration.pinned
        statusViewModel.isReplyInContext = configuration.isReplyInContext
        statusViewModel.hasReplyFollowing = configuration.hasReplyFollowing

        return statusViewModel
    }

    func loadMoreViewModel(item: CollectionItemIdentifier) -> LoadMoreViewModel? {
        guard let timelineItem = items[item],
              case let .loadMore(loadMore) = timelineItem
        else { return nil }

        if let cachedViewModel = viewModelCache[timelineItem]?.0 as? LoadMoreViewModel {
            return cachedViewModel
        }

        let loadMoreViewModel = LoadMoreViewModel(
            loadMoreService: collectionService.navigationService.loadMoreService(loadMore: loadMore))

        cache(viewModel: loadMoreViewModel, forItem: timelineItem)

        return loadMoreViewModel
    }

    func accountViewModel(item: CollectionItemIdentifier) -> AccountViewModel? {
        guard let timelineItem = items[item],
              case let .account(account) = timelineItem
        else { return nil }

        var accountViewModel: AccountViewModel

        if let cachedViewModel = viewModelCache[timelineItem]?.0 as? AccountViewModel {
            accountViewModel = cachedViewModel
        } else {
            accountViewModel = AccountViewModel(
                accountService: collectionService.navigationService.accountService(account: account))
            cache(viewModel: accountViewModel, forItem: timelineItem)
        }

        return accountViewModel
    }

    func cache(viewModel: CollectionItemViewModel, forItem item: CollectionItem) {
        viewModelCache[item] = (viewModel, viewModel.events.flatMap { $0.compactMap(NavigationEvent.init) }
                                    .assignErrorsToAlertItem(to: \.alertItem, on: self)
                                    .sink { [weak self] in self?.navigationEventsSubject.send($0) })
    }

    func process(sections: [[CollectionItem]]) {
        determineIfScrollPositionShouldBeMaintained(newSections: sections)

        let timelineItemKeys = Set(sections.reduce([], +))

        items = Dictionary(uniqueKeysWithValues: timelineItemKeys.map { (.init(item: $0), $0) })
        viewModelCache = viewModelCache.filter { timelineItemKeys.contains($0.key) }
    }

    func determineIfScrollPositionShouldBeMaintained(newSections: [[CollectionItem]]) {
        maintainScrollPositionOfItem = nil // clear old value

        // Maintain scroll position of parent after initial load of context
        if let contextParentID = collectionService.contextParentID {
            let contextParentIdentifier = CollectionItemIdentifier(id: contextParentID, kind: .status, info: [:])

            if identifiers == [[], [contextParentIdentifier], []] || identifiers.isEmpty {
                maintainScrollPositionOfItem = contextParentIdentifier
            }
        }
    }
}
