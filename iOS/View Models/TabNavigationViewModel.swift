// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class TabNavigationViewModel: ObservableObject {
    @Published private(set) var identity: Identity
    @Published private(set) var recentIdentities = [Identity]()
    @Published var presentingSecondaryNavigation = false
    @Published var alertItem: AlertItem?
    var selectedTab: Tab? = .timelines

    private let identityRepository: IdentityRepository
    private var cancellables = Set<AnyCancellable>()

    init(identityRepository: IdentityRepository) {
        self.identityRepository = identityRepository
        identity = identityRepository.identity
        identityRepository.$identity.dropFirst().assign(to: &$identity)

        identityRepository.recentIdentitiesObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$recentIdentities)
    }
}

extension TabNavigationViewModel {
    func refreshIdentity() {
        if identityRepository.isAuthorized {
            identityRepository.verifyCredentials()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink(receiveValue: {})
                .store(in: &cancellables)

            if identity.preferences.useServerPostingReadingPreferences {
                identityRepository.refreshServerPreferences()
                    .assignErrorsToAlertItem(to: \.alertItem, on: self)
                    .sink(receiveValue: {})
                    .store(in: &cancellables)
            }
        }

        identityRepository.refreshInstance()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }

    func secondaryNavigationViewModel() -> SecondaryNavigationViewModel {
        SecondaryNavigationViewModel(identityRepository: identityRepository)
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
        case .timelines: return "scroll"
        case .search: return "magnifyingglass"
        case .notifications: return "bell"
        case .messages: return "envelope"
        }
    }
}

extension TabNavigationViewModel.Tab: Identifiable {
    var id: Self { self }
}
