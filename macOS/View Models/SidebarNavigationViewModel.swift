// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class SidebarNavigationViewModel: ObservableObject {
    @Published private(set) var identity: Identity
    @Published private(set) var timelineViewModel: StatusListViewModel
    @Published var alertItem: AlertItem?
    var selectedTab: Tab? = .timelines

    private let identityService: IdentityService
    private var cancellables = Set<AnyCancellable>()

    init(identityService: IdentityService) {
        self.identityService = identityService
        identity = identityService.identity
        timelineViewModel = StatusListViewModel(statusListService: identityService.service(timeline: .home))
        identityService.$identity.dropFirst().assign(to: &$identity)
    }
}

extension SidebarNavigationViewModel {
    enum Tab: CaseIterable {
        case timelines
        case search
        case notifications
        case messages
    }
}

extension SidebarNavigationViewModel.Tab {
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

extension SidebarNavigationViewModel.Tab: Identifiable {
    var id: Self { self }
}
