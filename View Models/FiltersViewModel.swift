// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class FiltersViewModel: ObservableObject {
    @Published var filters = [Filter]()
    @Published var alertItem: AlertItem?

    private let identityService: IdentityService
    private var cancellables = Set<AnyCancellable>()

    init(identityService: IdentityService) {
        self.identityService = identityService

        identityService.filtersObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$filters)
    }
}

extension FiltersViewModel {
    func refreshFilters() {
        identityService.refreshFilters()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }

    func editFilterViewModel(filter: Filter) -> EditFilterViewModel {
        EditFilterViewModel(filter: filter, identityService: identityService)
    }
}
