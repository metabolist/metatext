// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class FiltersViewModel: ObservableObject {
    @Published var activeFilters = [Filter]()
    @Published var expiredFilters = [Filter]()
    @Published var alertItem: AlertItem?

    private let identityService: IdentityService
    private var cancellables = Set<AnyCancellable>()

    init(identityService: IdentityService) {
        self.identityService = identityService

        let now = Date()

        identityService.activeFiltersObservation(date: now)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$activeFilters)

        identityService.expiredFiltersObservation(date: now)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$expiredFilters)
    }
}

extension FiltersViewModel {
    func refreshFilters() {
        identityService.refreshFilters()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }

    func delete(filter: Filter) {
        identityService.deleteFilter(id: filter.id)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }

    func editFilterViewModel(filter: Filter) -> EditFilterViewModel {
        EditFilterViewModel(filter: filter, identityService: identityService)
    }
}
