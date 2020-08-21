// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class StatusesViewModel: ObservableObject {
    @Published private(set) var statusSections = [[Status]]()
    @Published var alertItem: AlertItem?
    @Published private(set) var loading = false
    let scrollToStatus: AnyPublisher<Status, Never>
    private let statusListService: StatusListService
    private let scrollToStatusInput = PassthroughSubject<Status, Never>()
    private var hasScrolledToParentAfterContextLoad = false
    private var cancellables = Set<AnyCancellable>()

    init(statusListService: StatusListService) {
        self.statusListService = statusListService
        scrollToStatus = scrollToStatusInput.eraseToAnyPublisher()

        statusListService.statusSections
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$statusSections)

        $statusSections
            .sink { [weak self] in
            guard let self = self else { return }

            if
                let contextParent = self.contextParent,
                !($0.first ?? []).isEmpty || !(($0.last ?? []).isEmpty),
                !self.hasScrolledToParentAfterContextLoad {
                self.hasScrolledToParentAfterContextLoad = true
                self.scrollToStatusInput.send(contextParent)
            }
        }
        .store(in: &cancellables)
    }
}

extension StatusesViewModel {
    var contextParent: Status? { statusListService.contextParent }

    func request(maxID: String? = nil, minID: String? = nil) {
        statusListService.request(maxID: maxID, minID: minID)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.loading = true },
                receiveCompletion: { [weak self] _ in self?.loading = false })
            .sink {}
            .store(in: &cancellables)
    }

    func statusViewModel(status: Status) -> StatusViewModel {
        var statusViewModel = Self.viewModelCache[status]
            ?? StatusViewModel(statusService: statusListService.statusService(status: status))

        statusViewModel.isContextParent = status == contextParent
        statusViewModel.isPinned = statusListService.isPinned(status: status)
        statusViewModel.isReplyInContext = statusListService.isReplyInContext(status: status)
        statusViewModel.hasReplyFollowing = statusListService.hasReplyFollowing(status: status)

        Self.viewModelCache[status] = statusViewModel

        return statusViewModel
    }

    func contextViewModel(status: Status) -> StatusesViewModel {
        StatusesViewModel(statusListService: statusListService.contextService(status: status))
    }
}

private extension StatusesViewModel {
    static var viewModelCache = [Status: StatusViewModel]()
}
