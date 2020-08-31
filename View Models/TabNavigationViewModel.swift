// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import Mastodon
import ServiceLayer

class TabNavigationViewModel: ObservableObject {
    @Published private(set) var identity: Identity
    @Published private(set) var recentIdentities = [Identity]()
    @Published var timeline = Timeline.home
    @Published private(set) var timelinesAndLists = Timeline.nonLists
    @Published var presentingSecondaryNavigation = false
    @Published var alertItem: AlertItem?
    var selectedTab: Tab? = .timelines

    private let identityService: IdentityService
    private var cancellables = Set<AnyCancellable>()

    init(identityService: IdentityService) {
        self.identityService = identityService
        identity = identityService.identity
        identityService.$identity.dropFirst().assign(to: &$identity)

        identityService.recentIdentitiesObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$recentIdentities)

        identityService.listsObservation()
            .map { Timeline.nonLists + $0 }
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$timelinesAndLists)
    }
}

extension TabNavigationViewModel {
    var timelineSubtitle: String {
        switch timeline {
        case .home, .list:
            return identity.handle
        case .local, .federated, .tag:
            return identity.instance?.uri ?? ""
        }
    }

    func title(timeline: Timeline) -> String {
        switch timeline {
        case .home:
            return NSLocalizedString("timelines.home", comment: "")
        case .local:
            return NSLocalizedString("timelines.local", comment: "")
        case .federated:
            return NSLocalizedString("timelines.federated", comment: "")
        case let .list(list):
            return list.title
        case let .tag(tag):
            return "#" + tag
        }
    }

    func systemImageName(timeline: Timeline) -> String {
        switch timeline {
        case .home: return "house"
        case .local: return "person.3"
        case .federated: return "globe"
        case .list: return "scroll"
        case .tag: return "number"
        }
    }

    func refreshIdentity() {
        if identityService.isAuthorized {
            identityService.verifyCredentials()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)

            identityService.refreshLists()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)

            identityService.refreshFilters()
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

    func viewModel(timeline: Timeline) -> StatusListViewModel {
        StatusListViewModel(statusListService: identityService.service(timeline: timeline))
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
