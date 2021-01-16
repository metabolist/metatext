// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class CollectionItemsViewModel: ObservableObject {
    @Published public var alertItem: AlertItem?
    public private(set) var nextPageMaxId: String?

    private let items = CurrentValueSubject<[[CollectionItem]], Never>([])
    private let collectionService: CollectionService
    private let identification: Identification
    private var viewModelCache = [CollectionItem: (viewModel: CollectionItemViewModel, events: AnyCancellable)]()
    private let eventsSubject = PassthroughSubject<CollectionItemEvent, Never>()
    private let loadingSubject = PassthroughSubject<Bool, Never>()
    private let expandAllSubject: CurrentValueSubject<ExpandAllState, Never>
    private var maintainScrollPositionItemId: CollectionItem.Id?
    private var topVisibleIndexPath = IndexPath(item: 0, section: 0)
    private let lastReadId = CurrentValueSubject<String?, Never>(nil)
    private var lastSelectedLoadMore: LoadMore?
    private var hasRequestedUsingMarker = false
    private var shouldRestorePositionOfLocalLastReadId = false
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

        if let markerTimeline = collectionService.markerTimeline {
            shouldRestorePositionOfLocalLastReadId =
                identification.appPreferences.positionBehavior(markerTimeline: markerTimeline) == .rememberPosition
            lastReadId.compactMap { $0 }
                .removeDuplicates()
                .debounce(for: 0.5, scheduler: DispatchQueue.global())
                .flatMap { identification.service.setLastReadId($0, forMarker: markerTimeline) }
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
        }
    }
}

extension CollectionItemsViewModel: CollectionViewModel {
    public var updates: AnyPublisher<CollectionUpdate, Never> {
        items.map { [weak self] in
            CollectionUpdate(items: $0,
                             maintainScrollPositionItemId: self?.maintainScrollPositionItemId)
        }
        .eraseToAnyPublisher()
    }

    public var title: AnyPublisher<String, Never> { collectionService.title }

    public var titleLocalizationComponents: AnyPublisher<[String], Never> {
        collectionService.titleLocalizationComponents
    }

    public var expandAll: AnyPublisher<ExpandAllState, Never> {
        expandAllSubject.eraseToAnyPublisher()
    }

    public var alertItems: AnyPublisher<AlertItem, Never> { $alertItem.compactMap { $0 }.eraseToAnyPublisher() }

    public var loading: AnyPublisher<Bool, Never> { loadingSubject.eraseToAnyPublisher() }

    public var events: AnyPublisher<CollectionItemEvent, Never> { eventsSubject.eraseToAnyPublisher() }

    public var shouldAdjustContentInset: Bool { collectionService is ContextService }

    public var preferLastPresentIdOverNextPageMaxId: Bool { collectionService.preferLastPresentIdOverNextPageMaxId }

    public func request(maxId: String? = nil, minId: String? = nil) {
        let publisher: AnyPublisher<Never, Error>

        if let markerTimeline = collectionService.markerTimeline,
           identification.appPreferences.positionBehavior(markerTimeline: markerTimeline) == .syncPosition,
           !hasRequestedUsingMarker {
            publisher = identification.service.getMarker(markerTimeline)
                .flatMap { [weak self] in
                    self?.collectionService.request(maxId: $0.lastReadId, minId: nil) ?? Empty().eraseToAnyPublisher()
                }
                .catch { [weak self] _ in
                    self?.collectionService.request(maxId: nil, minId: nil) ?? Empty().eraseToAnyPublisher()
                }
                .collect()
                .flatMap { [weak self] _ in
                    self?.collectionService.request(maxId: nil, minId: nil) ?? Empty().eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
            self.hasRequestedUsingMarker = true
        } else {
            publisher = collectionService.request(maxId: realMaxId(maxId: maxId), minId: minId)
        }

        publisher
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
        case let .notification(notification, _):
            if let status = notification.status {
                eventsSubject.send(
                    .navigation(.collection(collectionService
                                                .navigationService
                                                .contextService(id: status.displayStatus.id))))
            } else {
                eventsSubject.send(
                    .navigation(.profile(collectionService
                                            .navigationService
                                            .profileService(account: notification.account))))
            }
        case let .conversation(conversation):
            guard let status = conversation.lastStatus else { break }

            eventsSubject.send(
                .navigation(.collection(collectionService
                                            .navigationService
                                            .contextService(id: status.displayStatus.id))))
        }
    }

    public func viewedAtTop(indexPath: IndexPath) {
        topVisibleIndexPath = indexPath

        if !shouldRestorePositionOfLocalLastReadId,
           items.value.count > indexPath.section,
           items.value[indexPath.section].count > indexPath.item {
            lastReadId.send(items.value[indexPath.section][indexPath.item].itemId)
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

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    public func viewModel(indexPath: IndexPath) -> CollectionItemViewModel {
        let item = items.value[indexPath.section][indexPath.item]
        let cachedViewModel = viewModelCache[item]?.viewModel

        switch item {
        case let .status(status, configuration):
            let viewModel: StatusViewModel

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
                accountService: collectionService.navigationService.accountService(account: account),
                identification: identification)

            cache(viewModel: viewModel, forItem: item)

            return viewModel
        case let .notification(notification, statusConfiguration):
            let viewModel: CollectionItemViewModel

            if let cachedViewModel = cachedViewModel {
                viewModel = cachedViewModel
            } else if let status = notification.status, let statusConfiguration = statusConfiguration {
                let statusViewModel = StatusViewModel(
                    statusService: collectionService.navigationService.statusService(status: status),
                    identification: identification)
                statusViewModel.configuration = statusConfiguration
                viewModel = statusViewModel
                cache(viewModel: viewModel, forItem: item)
            } else {
                viewModel = NotificationViewModel(
                    notificationService: collectionService.navigationService.notificationService(
                        notification: notification),
                    identification: identification)
                cache(viewModel: viewModel, forItem: item)
            }

            return viewModel
        case let .conversation(conversation):
            if let cachedViewModel = cachedViewModel {
                return cachedViewModel
            }

            let viewModel = ConversationViewModel(
                conversationService: collectionService.navigationService.conversationService(
                    conversation: conversation),
                identification: identification)

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
        viewModelCache[item] = (viewModel, viewModel.events
                                    .flatMap { [weak self] events -> AnyPublisher<CollectionItemEvent, Never> in
                                        guard let self = self else { return Empty().eraseToAnyPublisher() }

                                        return events.assignErrorsToAlertItem(to: \.alertItem, on: self)
                                            .eraseToAnyPublisher()
                                    }
                                    .sink { [weak self] in self?.eventsSubject.send($0) })
    }

    func process(items: [[CollectionItem]]) {
        maintainScrollPositionItemId = idForScrollPositionMaintenance(newItems: items)
        self.items.send(items)

        let itemsSet = Set(items.reduce([], +))

        viewModelCache = viewModelCache.filter { itemsSet.contains($0.key) }
    }

    func realMaxId(maxId: String?) -> String? {
        guard let maxId = maxId else { return nil }

        guard let markerTimeline = collectionService.markerTimeline,
              identification.appPreferences.positionBehavior(markerTimeline: markerTimeline) == .rememberPosition,
              let lastItemId = items.value.last?.last?.itemId
        else { return maxId }

        return min(maxId, lastItemId)
    }

    func idForScrollPositionMaintenance(newItems: [[CollectionItem]]) -> CollectionItem.Id? {
        let flatItems = items.value.reduce([], +)
        let flatNewItems = newItems.reduce([], +)

        if shouldRestorePositionOfLocalLastReadId,
           let markerTimeline = collectionService.markerTimeline,
           let localLastReadId = identification.service.getLocalLastReadId(markerTimeline),
           flatNewItems.contains(where: { $0.itemId == localLastReadId }) {
            shouldRestorePositionOfLocalLastReadId = false

            return localLastReadId
        }

        if collectionService is ContextService,
           items.value.isEmpty || items.value.map(\.count) == [0, 1, 0],
           let contextParent = flatNewItems.first(where: {
            guard case let .status(_, configuration) = $0 else { return false }

            return configuration.isContextParent // Maintain scroll position of parent after initial load of context
           }) {
            return contextParent.itemId
        } else if collectionService is TimelineService {
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
                        return statusAfterLoadMore.itemId
                    }
                }
            }

            if items.value.count > topVisibleIndexPath.section,
               items.value[topVisibleIndexPath.section].count > topVisibleIndexPath.item {
                let topVisibleItem = items.value[topVisibleIndexPath.section][topVisibleIndexPath.item]

                if newItems.count > topVisibleIndexPath.section,
                   let newIndex = newItems[topVisibleIndexPath.section]
                    .firstIndex(where: { $0.itemId == topVisibleItem.itemId }),
                   newIndex > topVisibleIndexPath.item {
                    return topVisibleItem.itemId
                }
            }
        }

        return nil
    }
}
