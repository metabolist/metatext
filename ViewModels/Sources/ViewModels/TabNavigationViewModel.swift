// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public class TabNavigationViewModel: ObservableObject {
    @Published public private(set) var identity: Identity
    @Published public private(set) var recentIdentities = [Identity]()
    @Published public var timeline = Timeline.home
    @Published public private(set) var timelinesAndLists = Timeline.nonLists
    @Published public var presentingSecondaryNavigation = false
    @Published public var alertItem: AlertItem?
    public var selectedTab: Tab? = .timelines

    private let environment: IdentifiedEnvironment
    private var cancellables = Set<AnyCancellable>()

    init(environment: IdentifiedEnvironment) {
        self.environment = environment
        identity = environment.identity
        environment.$identity.dropFirst().assign(to: &$identity)

        environment.identityService.recentIdentitiesObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$recentIdentities)

        environment.identityService.listsObservation()
            .map { Timeline.nonLists + $0 }
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$timelinesAndLists)
    }
}

public extension TabNavigationViewModel {
    var timelineSubtitle: String {
        switch timeline {
        case .home, .list:
            return identity.handle
        case .local, .federated, .tag:
            return identity.instance?.uri ?? ""
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
        if environment.identityService.isAuthorized {
            environment.identityService.verifyCredentials()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)

            environment.identityService.refreshLists()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)

            environment.identityService.refreshFilters()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)

            if identity.preferences.useServerPostingReadingPreferences {
                environment.identityService.refreshServerPreferences()
                    .assignErrorsToAlertItem(to: \.alertItem, on: self)
                    .sink { _ in }
                    .store(in: &cancellables)
            }
        }

        environment.identityService.refreshInstance()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }

    func secondaryNavigationViewModel() -> SecondaryNavigationViewModel {
        SecondaryNavigationViewModel(environment: environment)
    }

    func viewModel(timeline: Timeline) -> StatusListViewModel {
        StatusListViewModel(statusListService: environment.identityService.service(timeline: timeline))
    }
}

public extension TabNavigationViewModel {
    enum Tab: CaseIterable {
        case timelines
        case search
        case notifications
        case messages
    }
}

extension TabNavigationViewModel.Tab: Identifiable {
    public var id: Self { self }
}
