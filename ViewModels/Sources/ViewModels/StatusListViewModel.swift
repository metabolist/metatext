// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public class StatusListViewModel: ObservableObject {
    @Published public private(set) var items = [[CollectionItem]]()
    @Published public var alertItem: AlertItem?
    public let navigationEvents: AnyPublisher<NavigationEvent, Never>
    public private(set) var nextPageMaxID: String?
    public private(set) var maintainScrollPositionOfItem: CollectionItem?

    private var statuses = [String: Status]()
    private var flatStatusIDs = [String]()
    private let statusListService: StatusListService
    private var statusViewModelCache = [Status: (StatusViewModel, AnyCancellable)]()
    private let navigationEventsSubject = PassthroughSubject<NavigationEvent, Never>()
    private let loadingSubject = PassthroughSubject<Bool, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(statusListService: StatusListService) {
        self.statusListService = statusListService
        navigationEvents = navigationEventsSubject.eraseToAnyPublisher()

        statusListService.statusSections
            .combineLatest(statusListService.filters.map { $0.regularExpression() })
            .map(Self.filter(statusSections:regularExpression:))
            .handleEvents(receiveOutput: { [weak self] in
                self?.determineIfScrollPositionShouldBeMaintained(newStatusSections: $0)
                self?.cleanViewModelCache(newStatusSections: $0)
                self?.statuses = Dictionary(uniqueKeysWithValues: Set($0.reduce([], +)).map { ($0.id, $0) })
                self?.flatStatusIDs = $0.reduce([], +).map(\.id)
            })
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .map { $0.map { $0.map { CollectionItem(id: $0.id, kind: .status) } } }
            .assign(to: &$items)

        statusListService.nextPageMaxIDs
            .sink { [weak self] in self?.nextPageMaxID = $0 }
            .store(in: &cancellables)
    }

    public var title: AnyPublisher<String?, Never> { Just(statusListService.title).eraseToAnyPublisher() }

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

    func isPinned(status: Status) -> Bool { false }
}

extension StatusListViewModel: CollectionViewModel {
    public var collectionItems: AnyPublisher<[[CollectionItem]], Never> { $items.eraseToAnyPublisher() }

    public var alertItems: AnyPublisher<AlertItem, Never> { $alertItem.compactMap { $0 }.eraseToAnyPublisher() }

    public var loading: AnyPublisher<Bool, Never> { loadingSubject.eraseToAnyPublisher() }

    public func itemSelected(_ item: CollectionItem) {
        switch item.kind {
        case .status:
            let displayStatusID = statuses[item.id]?.displayStatus.id ?? item.id

            navigationEventsSubject.send(
                .collectionNavigation(
                    StatusListViewModel(
                        statusListService: statusListService
                            .navigationService
                            .contextStatusListService(id: displayStatusID))))
        default:
            break
        }
    }

    public func canSelect(item: CollectionItem) -> Bool {
        if case .status = item.kind, item.id == statusListService.contextParentID {
            return false
        }

        return true
    }

    public func viewModel(item: CollectionItem) -> Any? {
        switch item.kind {
        case .status:
            return statusViewModel(id: item.id)
        default:
            return nil
        }
    }
}

private extension StatusListViewModel {
    static func filter(statusSections: [[Status]], regularExpression: String?) -> [[Status]] {
        guard let regEx = regularExpression else { return statusSections }

        return statusSections.map {
            $0.filter { $0.filterableContent.range(of: regEx, options: [.regularExpression, .caseInsensitive]) == nil }
        }
    }

    var contextParentID: String? { statusListService.contextParentID }

    func statusViewModel(id: String) -> StatusViewModel? {
        guard let status = statuses[id] else { return nil }

        var statusViewModel: StatusViewModel

        if let cachedViewModel = statusViewModelCache[status]?.0 {
            statusViewModel = cachedViewModel
        } else {
            statusViewModel = StatusViewModel(
                statusService: statusListService.navigationService.statusService(status: status))
            statusViewModelCache[status] = (statusViewModel,
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

        statusViewModel.isContextParent = status.id == statusListService.contextParentID
        statusViewModel.isPinned = isPinned(status: status)
        statusViewModel.isReplyInContext = isReplyInContext(status: status)
        statusViewModel.hasReplyFollowing = hasReplyFollowing(status: status)

        return statusViewModel
    }

    func determineIfScrollPositionShouldBeMaintained(newStatusSections: [[Status]]) {
        maintainScrollPositionOfItem = nil // clear old value

        // Maintain scroll position of parent after initial load of context
        if let contextParentID = contextParentID, flatStatusIDs == [contextParentID] || flatStatusIDs == [] {
            maintainScrollPositionOfItem = CollectionItem(id: contextParentID, kind: .status)
        }
    }

    func cleanViewModelCache(newStatusSections: [[Status]]) {
        let newStatuses = Set(newStatusSections.reduce([], +))

        statusViewModelCache = statusViewModelCache.filter { newStatuses.contains($0.key) }
    }

    func isReplyInContext(status: Status) -> Bool {
        guard
            let index = flatStatusIDs.firstIndex(where: { $0 == status.id }),
            index > 0
        else { return false }

        let previousStatusID = flatStatusIDs[index - 1]

        return previousStatusID != contextParentID && status.inReplyToId == previousStatusID
    }

    func hasReplyFollowing(status: Status) -> Bool {
        guard
            let index = flatStatusIDs.firstIndex(where: { $0 == status.id }),
            flatStatusIDs.count > index + 1,
            let nextStatus = statuses[flatStatusIDs[index + 1]]
        else { return false }

        return status.id != contextParentID && nextStatus.inReplyToId == status.id
    }
}
