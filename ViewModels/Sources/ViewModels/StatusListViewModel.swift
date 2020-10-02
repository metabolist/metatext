// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

final public class StatusListViewModel: ObservableObject {
    @Published public private(set) var items = [[CollectionItemIdentifier]]()
    @Published public var alertItem: AlertItem?
    public private(set) var nextPageMaxID: String?
    public private(set) var maintainScrollPositionOfItem: CollectionItemIdentifier?

    private var timelineItems = [CollectionItemIdentifier: Timeline.Item]()
    private var flatStatusIDs = [String]()
    private let statusListService: StatusListService
    private var viewModelCache = [Timeline.Item: (Any, AnyCancellable)]()
    private let navigationEventsSubject = PassthroughSubject<NavigationEvent, Never>()
    private let loadingSubject = PassthroughSubject<Bool, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(statusListService: StatusListService) {
        self.statusListService = statusListService

        statusListService.sections
            .handleEvents(receiveOutput: { [weak self] in self?.process(sections: $0) })
            .map { $0.map { $0.map(CollectionItemIdentifier.init(timelineItem:)) } }
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$items)

        statusListService.nextPageMaxIDs
            .sink { [weak self] in self?.nextPageMaxID = $0 }
            .store(in: &cancellables)
    }
}

extension StatusListViewModel: CollectionViewModel {
    public var collectionItems: AnyPublisher<[[CollectionItemIdentifier]], Never> { $items.eraseToAnyPublisher() }

    public var title: AnyPublisher<String?, Never> { Just(statusListService.title).eraseToAnyPublisher() }

    public var alertItems: AnyPublisher<AlertItem, Never> { $alertItem.compactMap { $0 }.eraseToAnyPublisher() }

    public var loading: AnyPublisher<Bool, Never> { loadingSubject.eraseToAnyPublisher() }

    public var navigationEvents: AnyPublisher<NavigationEvent, Never> { navigationEventsSubject.eraseToAnyPublisher() }

    public func request(maxID: String? = nil, minID: String? = nil) {
        statusListService.request(maxID: maxID, minID: minID)
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.loadingSubject.send(true) },
                receiveCompletion: { [weak self] _ in self?.loadingSubject.send(false) })
            .sink { _ in }
            .store(in: &cancellables)
    }

    public func itemSelected(_ item: CollectionItemIdentifier) {
        guard let timelineItem = timelineItems[item] else { return }

        switch timelineItem {
        case let .status(configuration):
            navigationEventsSubject.send(
                .collectionNavigation(
                    StatusListViewModel(
                        statusListService: statusListService
                            .navigationService
                            .contextStatusListService(id: configuration.status.displayStatus.id))))
        default:
            break
        }
    }

    public func canSelect(item: CollectionItemIdentifier) -> Bool {
        if case .status = item.kind, item.id == statusListService.contextParentID {
            return false
        }

        return true
    }

    public func viewModel(item: CollectionItemIdentifier) -> Any? {
        switch item.kind {
        case .status:
            return statusViewModel(item: item)
        default:
            return nil
        }
    }
}

private extension StatusListViewModel {
    func statusViewModel(item: CollectionItemIdentifier) -> StatusViewModel? {
        guard let timelineItem = timelineItems[item],
              case let .status(configuration) = timelineItem
        else { return nil }

        var statusViewModel: StatusViewModel

        if let cachedViewModel = viewModelCache[timelineItem]?.0 as? StatusViewModel {
            statusViewModel = cachedViewModel
        } else {
            statusViewModel = StatusViewModel(
                statusService: statusListService.navigationService.statusService(status: configuration.status))
            viewModelCache[timelineItem] = (statusViewModel,
                                      statusViewModel.events
                                        .flatMap { $0 }
                                        .assignErrorsToAlertItem(to: \.alertItem, on: self)
                                        .sink { [weak self] in
                                            guard
                                                let self = self,
                                                let event = NavigationEvent($0)
                                            else { return }

                                            self.navigationEventsSubject.send(event)
                                        })
        }

        statusViewModel.isContextParent = configuration.status.id == statusListService.contextParentID
        statusViewModel.isPinned = configuration.pinned
        statusViewModel.isReplyInContext = configuration.isReplyInContext
        statusViewModel.hasReplyFollowing = configuration.hasReplyFollowing

        return statusViewModel
    }

    func process(sections: [[Timeline.Item]]) {
        determineIfScrollPositionShouldBeMaintained(newSections: sections)

        let timelineItemKeys = Set(sections.reduce([], +))

        timelineItems = Dictionary(uniqueKeysWithValues: timelineItemKeys.map { (.init(timelineItem: $0), $0) })
        viewModelCache = viewModelCache.filter { timelineItemKeys.contains($0.key) }
    }

    func determineIfScrollPositionShouldBeMaintained(newSections: [[Timeline.Item]]) {
        maintainScrollPositionOfItem = nil // clear old value

        // Maintain scroll position of parent after initial load of context
        if let contextParentID = statusListService.contextParentID {
            let contextParentIdentifier = CollectionItemIdentifier(id: contextParentID, kind: .status, info: [:])

            if items == [[], [contextParentIdentifier], []] || items.isEmpty {
                maintainScrollPositionOfItem = contextParentIdentifier
            }
        }
    }
}
