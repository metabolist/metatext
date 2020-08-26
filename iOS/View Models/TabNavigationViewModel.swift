// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class TabNavigationViewModel: ObservableObject {
    @Published private(set) var identity: Identity
    @Published private(set) var recentIdentities = [Identity]()
    @Published private(set) var timelineViewModel: StatusesViewModel
    @Published var presentingSecondaryNavigation = false
    @Published var alertItem: AlertItem?
    var selectedTab: Tab? = .timelines

    private let identityService: IdentityService
    private var cancellables = Set<AnyCancellable>()

    init(identityService: IdentityService) {
        self.identityService = identityService
        identity = identityService.identity
        timelineViewModel = StatusesViewModel(statusListService: identityService.service(timeline: .home))
        identityService.$identity.dropFirst().assign(to: &$identity)

        identityService.recentIdentitiesObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$recentIdentities)
    }
}

extension TabNavigationViewModel {
    func refreshIdentity() {
        if identityService.isAuthorized {
            identityService.verifyCredentials()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)

            if identity.preferences.useServerPostingReadingPreferences {
                identityService.refreshServerPreferences()
                    .assignErrorsToAlertItem(to: \.alertItem, on: self)
                    .sink { _ in }
                    .store(in: &cancellables)
            }
        }

        identityService.refreshInstance()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }

    func secondaryNavigationViewModel() -> SecondaryNavigationViewModel {
        SecondaryNavigationViewModel(identityService: identityService)
    }
}

extension TabNavigationViewModel {
    enum Tab: CaseIterable {
        case timelines
        case search
        case notifications
        case messages
    }
}

extension TabNavigationViewModel.Tab {
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
        case .timelines: return "newspaper"
        case .search: return "magnifyingglass"
        case .notifications: return "bell"
        case .messages: return "envelope"
        }
    }
}

extension TabNavigationViewModel.Tab: Identifiable {
    var id: Self { self }
}
