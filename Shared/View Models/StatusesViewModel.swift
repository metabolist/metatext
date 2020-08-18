// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class StatusesViewModel: ObservableObject {
    @Published var statusSections = [[Status]]()
    @Published var alertItem: AlertItem?
    private let statusListService: StatusListService
    private var cancellables = Set<AnyCancellable>()

    init(statusListService: StatusListService) {
        self.statusListService = statusListService

        statusListService.statusSections
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$statusSections)
    }
}

extension StatusesViewModel {
    func request(maxID: String? = nil, minID: String? = nil) {
        statusListService.request(maxID: maxID, minID: minID)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink {}
            .store(in: &cancellables)
    }
}
