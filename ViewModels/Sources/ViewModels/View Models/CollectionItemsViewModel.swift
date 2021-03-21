// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public class CollectionItemsViewModel: ObservableObject {
    public let identityContext: IdentityContext
    @Published public var alertItem: AlertItem?
    public private(set) var nextPageMaxId: String?

    @Published private var lastUpdate = CollectionUpdate.empty
    private let collectionService: CollectionService
    private var viewModelCache = [CollectionItem: Any]()
    private let eventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()
    private let loadingSubject = PassthroughSubject<Bool, Never>()
    private let expandAllSubject: CurrentValueSubject<ExpandAllState, Never>
    private let searchScopeChangesSubject = PassthroughSubject<SearchScope, Never>()
    private var topVisibleIndexPath = IndexPath(item: 0, section: 0)
    private let lastReadId = CurrentValueSubject<String?, Never>(nil)
    private var lastSelectedLoadMore: LoadMore?
    private var localLastReadId: CollectionItem.Id?
    private var markerLastReadId: CollectionItem.Id?
    private var cancellables = Set<AnyCancellable>()
    private var requestCancellables = Set<AnyCancellable>()

    // swiftlint:disable:next function_body_length
    public init(collectionService: CollectionService, identityContext: IdentityContext) {
        self.collectionService = collectionService
        self.identityContext = identityContext
        expandAllSubject = CurrentValueSubject(
            collectionService is ContextService && !identityContext.identity.preferences.readingExpandSpoilers
                ? .expand : .hidden)

        collectionService.sections
            .handleEvents(receiveOutput: { [weak self] in self?.process(sections: $0) })
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)

        collectionService.nextPageMaxId
            .sink { [weak self] in self?.nextPageMaxId = $0 }
            .store(in: &cancellables)

        collectionService.accountIdsForRelationships
            .filter { !$0.isEmpty }
            .flatMap(identityContext.service.requestRelationships(ids:))
            .catch { _ in Empty().setFailureType(to: Never.self) }
            .sink { _ in }
            .store(in: &cancellables)

        let debouncedLastReadId = lastReadId
            .compactMap { $0 }
            .removeDuplicates()
            .debounce(for: .seconds(Self.lastReadIdDebounceInterval), scheduler: DispatchQueue.global())
            .share()

        debouncedLastReadId
            .filter { [weak self] in
                guard let markerLastReadId = self?.markerLastReadId else { return false }

                return $0 > markerLastReadId
            }
            .flatMap { collectionService.setMarkerLastReadId($0) }
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] in self?.markerLastReadId = $0 }
            .store(in: &cancellables)

        if let timeline = collectionService.positionTimeline {
            if identityContext.appPreferences.positionBehavior(timeline: timeline) == .localRememberPosition {
                localLastReadId = identityContext.service.getLocalLastReadId(timeline: timeline)
            }

            debouncedLastReadId
                .filter { _ in
                    identityContext.appPreferences.positionBehavior(timeline: timeline) == .localRememberPosition
                }
                .flatMap { identityContext.service.setLocalLastReadId($0, timeline: timeline) }
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
        }
    }

    public var updates: AnyPublisher<CollectionUpdate, Never> {
        $lastUpdate.eraseToAnyPublisher()
    }

    public func requestNextPage(fromIndexPath indexPath: IndexPath) {
        guard let maxId = collectionService.preferLastPresentIdOverNextPageMaxId
                ? lastUpdate.sections[indexPath.section].items[indexPath.item].itemId
                : nextPageMaxId
        else { return }

        request(maxId: maxId, minId: nil, search: nil)
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    public func viewModel(indexPath: IndexPath) -> Any {
        let item = lastUpdate.sections[indexPath.section].items[indexPath.item]
        let cachedViewModel = viewModelCache[item]

        switch item {
        case let .status(status, configuration, relationship):
            let viewModel: StatusViewModel

            if let cachedViewModel = cachedViewModel as? StatusViewModel {
                viewModel = cachedViewModel
            } else {
                viewModel = .init(
                    statusService: collectionService.navigationService.statusService(status: status),
                    identityContext: identityContext,
                    eventsSubject: eventsSubject)
                viewModelCache[item] = viewModel
            }

            viewModel.configuration = configuration
            viewModel.accountViewModel.relationship = relationship

            return viewModel
        case let .loadMore(loadMore):
            if let cachedViewModel = cachedViewModel {
                return cachedViewModel
            }

            let viewModel = LoadMoreViewModel(
                loadMoreService: collectionService.navigationService.loadMoreService(loadMore: loadMore),
                eventsSubject: eventsSubject,
                identityContext: identityContext)

            viewModelCache[item] = viewModel

            return viewModel
        case let .account(account, configuration, relationship):
            let viewModel: AccountViewModel

            if let cachedViewModel = cachedViewModel as? AccountViewModel {
                viewModel = cachedViewModel
            } else {
                viewModel = AccountViewModel(
                    accountService: collectionService.navigationService.accountService(account: account),
                    identityContext: identityContext,
                    eventsSubject: eventsSubject)
                viewModelCache[item] = viewModel
            }

            viewModel.configuration = configuration
            viewModel.relationship = relationship

            return viewModel
        case let .notification(notification, statusConfiguration):
            let viewModel: Any

            if let cachedViewModel = cachedViewModel {
                viewModel = cachedViewModel
            } else if let status = notification.status, let statusConfiguration = statusConfiguration {
                let statusViewModel = StatusViewModel(
                    statusService: collectionService.navigationService.statusService(status: status),
                    identityContext: identityContext,
                    eventsSubject: eventsSubject)
                statusViewModel.configuration = statusConfiguration
                viewModel = statusViewModel
                viewModelCache[item] = viewModel
            } else {
                viewModel = NotificationViewModel(
                    notificationService: collectionService.navigationService.notificationService(
                        notification: notification),
                    identityContext: identityContext,
                    eventsSubject: eventsSubject)
                viewModelCache[item] = viewModel
            }

            return viewModel
        case let .conversation(conversation):
            if let cachedViewModel = cachedViewModel {
                return cachedViewModel
            }

            let viewModel = ConversationViewModel(
                conversationService: collectionService.navigationService.conversationService(
                    conversation: conversation),
                identityContext: identityContext)

            viewModelCache[item] = viewModel

            return viewModel
        case let .tag(tag):
            if let cachedViewModel = cachedViewModel {
                return cachedViewModel
            }

            let viewModel = TagViewModel(tag: tag, identityContext: identityContext)

            viewModelCache[item] = viewModel

            return viewModel
        case let .moreResults(moreResults):
            if let cachedViewModel = cachedViewModel {
                return cachedViewModel
            }

            let viewModel = MoreResultsViewModel(moreResults: moreResults)

            viewModelCache[item] = viewModel

            return viewModel
        }
    }
}

extension CollectionItemsViewModel: CollectionViewModel {
    public var title: AnyPublisher<String, Never> { collectionService.title }

    public var titleLocalizationComponents: AnyPublisher<[String], Never> {
        collectionService.titleLocalizationComponents
    }

    public var expandAll: AnyPublisher<ExpandAllState, Never> {
        expandAllSubject.eraseToAnyPublisher()
    }

    public var alertItems: AnyPublisher<AlertItem, Never> { $alertItem.compactMap { $0 }.eraseToAnyPublisher() }

    public var loading: AnyPublisher<Bool, Never> { loadingSubject.eraseToAnyPublisher() }

    public var events: AnyPublisher<CollectionItemEvent, Never> {
        eventsSubject.flatMap { [weak self] eventPublisher -> AnyPublisher<CollectionItemEvent, Never> in
            guard let self = self else { return Empty().eraseToAnyPublisher() }

            return eventPublisher.assignErrorsToAlertItem(to: \.alertItem, on: self).eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    public var searchScopeChanges: AnyPublisher<SearchScope, Never> { searchScopeChangesSubject.eraseToAnyPublisher() }

    public var canRefresh: Bool { collectionService.canRefresh }

    public var announcesNewItems: Bool { collectionService.announcesNewItems }

    public func request(maxId: String? = nil, minId: String? = nil, search: Search?) {
        collectionService.request(maxId: realMaxId(maxId: maxId), minId: minId, search: search)
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.loadingSubject.send(true) },
                receiveCompletion: { [weak self] _ in self?.loadingSubject.send(false) })
            .sink { _ in }
            .store(in: &requestCancellables)
        collectionService.requestMarkerLastReadId()
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] in self?.markerLastReadId = $0 }
            .store(in: &cancellables)

    }

    public func cancelRequests() {
        for cancellable in requestCancellables {
            cancellable.cancel()
        }
    }

    public func select(indexPath: IndexPath) {
        let item = lastUpdate.sections[indexPath.section].items[indexPath.item]

        switch item {
        case let .status(status, _, _):
            send(event: .navigation(.collection(collectionService
                                                    .navigationService
                                                    .contextService(id: status.displayStatus.id))))
        case let .loadMore(loadMore):
            lastSelectedLoadMore = loadMore
            (viewModel(indexPath: indexPath) as? LoadMoreViewModel)?.loadMore()
        case let .account(account, _, relationship):
            send(event: .navigation(.profile(collectionService
                                                .navigationService
                                                .profileService(account: account, relationship: relationship))))
        case let .notification(notification, _):
            if let status = notification.status {
                send(event: .navigation(.collection(collectionService
                                                        .navigationService
                                                        .contextService(id: status.displayStatus.id))))
            } else {
                send(event: .navigation(.profile(collectionService
                                                    .navigationService
                                                    .profileService(account: notification.account))))
            }
        case let .conversation(conversation):
            guard let status = conversation.lastStatus else { break }

            (collectionService as? ConversationsService)?.markConversationAsRead(id: conversation.id)
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)

            send(event: .navigation(.collection(collectionService
                                                    .navigationService
                                                    .contextService(id: status.displayStatus.id))))
        case let .tag(tag):
            send(event: .navigation(.collection(collectionService
                                                    .navigationService
                                                    .timelineService(timeline: .tag(tag.name)))))
        case let .moreResults(moreResults):
            searchScopeChangesSubject.send(moreResults.scope)
        }
    }

    public func viewedAtTop(indexPath: IndexPath) {
        topVisibleIndexPath = indexPath

        if lastUpdate.sections.count > indexPath.section,
           lastUpdate.sections[indexPath.section].items.count > indexPath.item {
            lastReadId.send(lastUpdate.sections[indexPath.section].items[indexPath.item].itemId)
        }
    }

    public func canSelect(indexPath: IndexPath) -> Bool {
        switch lastUpdate.sections[indexPath.section].items[indexPath.item] {
        case let .status(_, configuration, _):
            return !configuration.isContextParent
        case .loadMore:
            return !((viewModel(indexPath: indexPath) as? LoadMoreViewModel)?.loading ?? false)
        default:
            return true
        }
    }

    public func toggleExpandAll() {
        let statusIds = Set(lastUpdate.sections.map(\.items).reduce([], +).compactMap { item -> Status.Id? in
            guard case let .status(status, _, _) = item else { return nil }

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

    public func applyAccountListEdit(viewModel: AccountViewModel, edit: CollectionItemEvent.AccountListEdit) {
        (collectionService as? AccountListService)?.remove(id: viewModel.id)
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)

        switch edit {
        case .acceptFollowRequest, .rejectFollowRequest:
            identityContext.service.verifyCredentials()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)
        }
    }
}

extension CollectionItemsViewModel {
    func sendDirectMessage(accountViewModel: AccountViewModel) {
        eventsSubject.send(
            Just(.compose(directMessageTo: accountViewModel))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }
}

private extension CollectionItemsViewModel {
    private static let lastReadIdDebounceInterval: TimeInterval = 0.5

    func send(event: CollectionItemEvent) {
        eventsSubject.send(Just(event).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    var lastUpdateWasContextParentOnly: Bool {
        collectionService is ContextService && lastUpdate.sections.map(\.items).map(\.count) == [0, 1, 0]
    }

    func process(sections: [CollectionSection]) {
        let items = sections.map(\.items).reduce([], +)
        let itemsSet = Set(items)

        self.lastUpdate = .init(
            sections: sections,
            maintainScrollPositionItemId: idForScrollPositionMaintenance(newSections: sections),
            shouldAdjustContentInset: lastUpdateWasContextParentOnly && items.count > 1)

        viewModelCache = viewModelCache.filter { itemsSet.contains($0.key) }
    }

    func realMaxId(maxId: String?) -> String? {
        guard let maxId = maxId else { return nil }

        guard let timeline = collectionService.positionTimeline,
              identityContext.appPreferences.positionBehavior(timeline: timeline) == .localRememberPosition,
              let lastItemId = lastUpdate.sections.last?.items.last?.itemId
        else { return maxId }

        return min(maxId, lastItemId)
    }

    func idForScrollPositionMaintenance(newSections: [CollectionSection]) -> CollectionItem.Id? {
        let items = lastUpdate.sections.map(\.items).reduce([], +)
        let newItems = newSections.map(\.items).reduce([], +)

        if let itemId = localLastReadId,
           newItems.contains(where: { $0.itemId == itemId }) {
            localLastReadId = nil

            return itemId
        }

        if collectionService is ContextService,
           lastUpdate.sections.isEmpty || lastUpdate.sections.map(\.items.count) == [0, 1, 0],
           let contextParent = newItems.first(where: {
            guard case let .status(_, configuration, _) = $0 else { return false }

            return configuration.isContextParent // Maintain scroll position of parent after initial load of context
           }) {
            return contextParent.itemId
        } else if collectionService is TimelineService || collectionService is NotificationsService {
            let difference = newItems.difference(from: items)

            if let lastSelectedLoadMore = lastSelectedLoadMore {
                for removal in difference.removals {
                    if case let .remove(_, item, _) = removal,
                       case let .loadMore(loadMore) = item,
                       loadMore == lastSelectedLoadMore,
                       let direction = (viewModelCache[item] as? LoadMoreViewModel)?.direction,
                       direction == .up,
                       let statusAfterLoadMore = items.first(where: {
                        guard case let .status(status, _, _) = $0 else { return false }

                        return status.id == loadMore.beforeStatusId
                       }) {
                        return statusAfterLoadMore.itemId
                    }
                }
            }

            if lastUpdate.sections.count > topVisibleIndexPath.section,
               lastUpdate.sections[topVisibleIndexPath.section].items.count > topVisibleIndexPath.item {
                let topVisibleItem = lastUpdate.sections[topVisibleIndexPath.section].items[topVisibleIndexPath.item]

                if newSections.count > topVisibleIndexPath.section,
                   let newIndex = newSections[topVisibleIndexPath.section]
                    .items.firstIndex(where: { $0.itemId == topVisibleItem.itemId }),
                   newIndex > topVisibleIndexPath.item {
                    return topVisibleItem.itemId
                }
            }
        }

        return nil
    }
}
