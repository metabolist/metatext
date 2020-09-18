// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public class StatusListViewModel: ObservableObject {
    @Published public private(set) var statusIDs = [[String]]()
    @Published public var alertItem: AlertItem?
    @Published public private(set) var loading = false
    public let events: AnyPublisher<Event, Never>
    public private(set) var maintainScrollPositionOfStatusID: String?

    private var statuses = [String: Status]()
    private let statusListService: StatusListService
    private var statusViewModelCache = [Status: (StatusViewModel, AnyCancellable)]()
    private let eventsSubject = PassthroughSubject<Event, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(statusListService: StatusListService) {
        self.statusListService = statusListService
        events = eventsSubject.eraseToAnyPublisher()

        statusListService.statusSections
            .combineLatest(statusListService.filters.map { $0.regularExpression() })
            .map(Self.filter(statusSections:regularExpression:))
            .handleEvents(receiveOutput: { [weak self] in
                self?.determineIfScrollPositionShouldBeMaintained(newStatusSections: $0)
                self?.cleanViewModelCache(newStatusSections: $0)
                self?.statuses = Dictionary(uniqueKeysWithValues: $0.reduce([], +).map { ($0.id, $0) })
            })
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .map { $0.map { $0.map(\.id) } }
            .assign(to: &$statusIDs)
    }

    public func request(maxID: String? = nil, minID: String? = nil) {
        statusListService.request(maxID: maxID, minID: minID)
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.loading = true },
                receiveCompletion: { [weak self] _ in self?.loading = false })
            .sink { _ in }
            .store(in: &cancellables)
    }

    func isPinned(status: Status) -> Bool { false }
}

public extension StatusListViewModel {
    enum Event {
        case statusListNavigation(StatusListViewModel)
        case urlNavigation(URL)
        case share(URL)
    }
}

public extension StatusListViewModel {
    var title: String? { statusListService.title }

    var paginates: Bool { statusListService.paginates }

    var contextParentID: String? { statusListService.contextParentID }

    func statusViewModel(id: String) -> StatusViewModel? {
        guard let status = statuses[id] else { return nil }

        var statusViewModel: StatusViewModel

        if let cachedViewModel = statusViewModelCache[status]?.0 {
            statusViewModel = cachedViewModel
        } else {
            statusViewModel = StatusViewModel(statusService: statusListService.statusService(status: status))
            statusViewModelCache[status] = (statusViewModel,
                                            statusViewModel.events
                                                .flatMap { $0 }
                                                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                                                .sink { [weak self] in
                                                    guard let self = self,
                                                          let event = self.event(statusEvent: $0)
                                                    else { return }
                                                    self.eventsSubject.send(event)
                                                })
        }

        statusViewModel.isContextParent = status.id == statusListService.contextParentID
        statusViewModel.isPinned = isPinned(status: status)
        statusViewModel.isReplyInContext = isReplyInContext(status: status)
        statusViewModel.hasReplyFollowing = hasReplyFollowing(status: status)

        return statusViewModel
    }

    func contextViewModel(id: String) -> StatusListViewModel {
        let displayStatusID = statuses[id]?.displayStatus.id ?? id

        return StatusListViewModel(statusListService: statusListService.contextService(statusID: displayStatusID))
    }
}

private extension StatusListViewModel {
    static func filter(statusSections: [[Status]], regularExpression: String?) -> [[Status]] {
        guard let regEx = regularExpression else { return statusSections }

        return statusSections.map {
            $0.filter { $0.filterableContent.range(of: regEx, options: [.regularExpression, .caseInsensitive]) == nil }
        }
    }

    func event(statusEvent: StatusViewModel.Event) -> Event? {
        switch statusEvent {
        case .ignorableOutput:
            return nil
        case let .navigation(item):
            switch item {
            case let .url(url):
                return .urlNavigation(url)
            case let .accountID(id):
                return .statusListNavigation(
                    AccountStatusesViewModel(accountStatusesService: statusListService.service(accountID: id)))
            case let .statusID(id):
                return .statusListNavigation(
                    StatusListViewModel(
                        statusListService: statusListService.contextService(statusID: id)))
            case let .tag(tag):
                return .statusListNavigation(
                    StatusListViewModel(
                        statusListService: statusListService.service(timeline: Timeline.tag(tag))))
            }
        case let .share(url):
            return .share(url)
        }
    }

    func determineIfScrollPositionShouldBeMaintained(newStatusSections: [[Status]]) {
        maintainScrollPositionOfStatusID = nil // clear old value

        let flatStatusIDs = statusIDs.reduce([], +)

        // Maintain scroll position of parent after initial load of context
        if let contextParentID = contextParentID, flatStatusIDs == [contextParentID] || flatStatusIDs == [] {
            maintainScrollPositionOfStatusID = contextParentID
        }
    }

    func cleanViewModelCache(newStatusSections: [[Status]]) {
        let newStatuses = Set(newStatusSections.reduce([], +))

        statusViewModelCache = statusViewModelCache.filter { newStatuses.contains($0.key) }
    }

    func isReplyInContext(status: Status) -> Bool {
        let flatStatusIDs = statusIDs.reduce([], +)

        guard
            let index = flatStatusIDs.firstIndex(where: { $0 == status.id }),
            index > 0
        else { return false }

        let previousStatusID = flatStatusIDs[index - 1]

        return previousStatusID != contextParentID && status.inReplyToId == previousStatusID
    }

    func hasReplyFollowing(status: Status) -> Bool {
        let flatStatusIDs = statusIDs.reduce([], +)

        guard
            let index = flatStatusIDs.firstIndex(where: { $0 == status.id }),
            flatStatusIDs.count > index + 1,
            let nextStatus = statuses[flatStatusIDs[index + 1]]
        else { return false }

        return status.id != contextParentID && nextStatus.inReplyToId == status.id
    }
}
