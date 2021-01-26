// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class FiltersViewModel: ObservableObject {
    @Published public var activeFilters = [Filter]()
    @Published public var expiredFilters = [Filter]()
    @Published public var alertItem: AlertItem?
    public let identityContext: IdentityContext

    private var cancellables = Set<AnyCancellable>()

    public init(identityContext: IdentityContext) {
        self.identityContext = identityContext

        identityContext.service.activeFiltersPublisher()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$activeFilters)

        identityContext.service.expiredFiltersPublisher()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$expiredFilters)
    }
}

public extension FiltersViewModel {
    func refreshFilters() {
        identityContext.service.refreshFilters()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }

    func delete(filter: Filter) {
        identityContext.service.deleteFilter(id: filter.id)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }
}
