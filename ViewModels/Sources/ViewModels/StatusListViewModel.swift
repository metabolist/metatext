// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import Mastodon
import ServiceLayer

public class StatusListViewModel: ObservableObject {
    @Published public private(set) var statusIDs = [[String]]()
    @Published public var alertItem: AlertItem?
    @Published public private(set) var loading = false
    public private(set) var maintainScrollPositionOfStatusID: String?

    private var statuses = [String: Status]()
    private let statusListService: StatusListService
    private var statusViewModelCache = [Status: (StatusViewModel, AnyCancellable)]()
    private var cancellables = Set<AnyCancellable>()

    init(statusListService: StatusListService) {
        self.statusListService = statusListService

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
}

public extension StatusListViewModel {
    var paginates: Bool { statusListService.paginates }

    var contextParentID: String? { statusListService.contextParentID }

    func request(maxID: String? = nil, minID: String? = nil) {
        statusListService.request(maxID: maxID, minID: minID)
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.loading = true },
                receiveCompletion: { [weak self] _ in self?.loading = false })
            .sink { _ in }
            .store(in: &cancellables)
    }

    func statusViewModel(id: String) -> StatusViewModel? {
        guard let status = statuses[id] else { return nil }

        var statusViewModel: StatusViewModel

        if let cachedViewModel = statusViewModelCache[status]?.0 {
            statusViewModel = cachedViewModel
        } else {
            statusViewModel = StatusViewModel(statusService: statusListService.statusService(status: status))
            statusViewModelCache[status] = (statusViewModel, statusViewModel.events
                .flatMap { $0 }
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in })
        }

        statusViewModel.isContextParent = status.id == statusListService.contextParentID
        statusViewModel.isPinned = status.displayStatus.pinned ?? false
        statusViewModel.isReplyInContext = isReplyInContext(status: status)
        statusViewModel.hasReplyFollowing = hasReplyFollowing(status: status)

        return statusViewModel
    }

    func contextViewModel(id: String) -> StatusListViewModel {
        StatusListViewModel(statusListService: statusListService.contextService(statusID: id))
    }
}

private extension StatusListViewModel {
    static func filter(statusSections: [[Status]], regularExpression: String?) -> [[Status]] {
        guard let regEx = regularExpression else { return statusSections }

        return statusSections.map {
            $0.filter { $0.filterableContent.range(of: regEx, options: [.regularExpression, .caseInsensitive]) == nil }
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
