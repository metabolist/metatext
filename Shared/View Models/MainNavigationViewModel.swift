// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class MainNavigationViewModel: ObservableObject {
    @Published private(set) var identity: Identity
    @Published private(set) var recentIdentities = [Identity]()
    @Published var presentingSettings = false
    @Published var alertItem: AlertItem?
    var selectedTab: Tab? = .timelines

    private let environment: IdentifiedEnvironment
    private var cancellables = Set<AnyCancellable>()

    init(environment: IdentifiedEnvironment) {
        self.environment = environment
        identity = environment.identity
        environment.$identity.dropFirst().assign(to: &$identity)

        environment.recentIdentitiesObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$recentIdentities)
    }
}

extension MainNavigationViewModel {
    func refreshIdentity() {
        if environment.isAuthorized {
            environment.verifyCredentials()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink(receiveValue: {})
                .store(in: &cancellables)

            if identity.preferences.useServerPostingReadingPreferences {
                environment.refreshServerPreferences()
                    .assignErrorsToAlertItem(to: \.alertItem, on: self)
                    .sink(receiveValue: {})
                    .store(in: &cancellables)
            }
        }

        environment.refreshInstance()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }

    func settingsViewModel() -> SecondaryNavigationViewModel {
        SecondaryNavigationViewModel(environment: environment)
    }
}

extension MainNavigationViewModel {
    enum Tab: CaseIterable {
        case timelines
        case search
        case notifications
        case messages
    }
}

extension MainNavigationViewModel.Tab {
    var title: String {
        switch self {
        case .timelines: return "Timelines"
        case .search: return "Search"
        case .notifications: return "Notifications"
        case .messages: return "Messages"
        }
    }

    var systemImageName: String {
        switch self {
        case .timelines: return "house"
        case .search: return "magnifyingglass"
        case .notifications: return "bell"
        case .messages: return "envelope"
        }
    }
}

extension MainNavigationViewModel.Tab: Identifiable {
    var id: Self { self }
}
