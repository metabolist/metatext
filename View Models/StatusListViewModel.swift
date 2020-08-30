// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import Mastodon

class StatusListViewModel: ObservableObject {
    @Published private(set) var statusIDs = [[String]]()
    @Published var alertItem: AlertItem?
    @Published private(set) var loading = false
    private(set) var maintainScrollPositionOfStatusID: String?

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
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .map { $0.map { $0.map(\.id) } }
            .assign(to: &$statusIDs)
    }
}

extension StatusListViewModel {
    var paginates: Bool { statusListService.paginates }

    var contextParentID: String? { statusListService.contextParentID }

    func request(maxID: String? = nil, minID: String? = nil) {
        statusListService.request(maxID: maxID, minID: minID)
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

        statusViewModel.isContextParent = status.id == contextParentID
        statusViewModel.isPinned = statusListService.isPinned(status: status)
        statusViewModel.isReplyInContext = statusListService.isReplyInContext(status: status)
        statusViewModel.hasReplyFollowing = statusListService.hasReplyFollowing(status: status)

        return statusViewModel
    }

    func contextViewModel(id: String) -> StatusListViewModel? {
        guard let status = statuses[id] else { return nil }

        return StatusListViewModel(statusListService: statusListService.contextService(status: status))
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

        // Maintain scroll position of parent after initial load of context
        if let contextParentID = contextParentID, statusIDs.reduce([], +) == [contextParentID] {
            maintainScrollPositionOfStatusID = contextParentID
        }
    }

    func cleanViewModelCache(newStatusSections: [[Status]]) {
        let newStatuses = Set(newStatusSections.reduce([], +))

        statusViewModelCache = statusViewModelCache.filter { newStatuses.contains($0.key) }
    }
}
