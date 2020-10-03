// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class FiltersViewModel: ObservableObject {
    @Published public var activeFilters = [Filter]()
    @Published public var expiredFilters = [Filter]()
    @Published public var alertItem: AlertItem?

    private let identification: Identification
    private var cancellables = Set<AnyCancellable>()

    public init(identification: Identification) {
        self.identification = identification

        identification.service.activeFiltersObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$activeFilters)

        identification.service.expiredFiltersObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$expiredFilters)
    }
}

public extension FiltersViewModel {
    func refreshFilters() {
        identification.service.refreshFilters()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }

    func delete(filter: Filter) {
        identification.service.deleteFilter(id: filter.id)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }
}
