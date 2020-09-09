// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class TabNavigationViewModel: ObservableObject {
    @Published public private(set) var identity: Identity
    @Published public private(set) var recentIdentities = [Identity]()
    @Published public var timeline: Timeline
    @Published public private(set) var timelinesAndLists: [Timeline]
    @Published public var presentingSecondaryNavigation = false
    @Published public var alertItem: AlertItem?
    public var selectedTab: Tab? = .timelines

    private let identification: Identification
    private var cancellables = Set<AnyCancellable>()

    public init(identification: Identification) {
        self.identification = identification
        identity = identification.identity
        timeline = identification.service.isAuthorized ? .home : .local
        timelinesAndLists = identification.service.isAuthorized
            ? Timeline.authenticatedDefaults
            : Timeline.unauthenticatedDefaults

        identification.$identity.dropFirst().assign(to: &$identity)
        identification.service.recentIdentitiesObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$recentIdentities)

        if identification.service.isAuthorized {
            identification.service.listsObservation()
                .map { Timeline.authenticatedDefaults + $0 }
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .assign(to: &$timelinesAndLists)
        }
    }
}

public extension TabNavigationViewModel {
    var tabs: [Tab] {
        if identification.service.isAuthorized {
            return Tab.allCases
        } else {
            return [.timelines, .explore]
        }
    }

    var timelineSubtitle: String {
        switch timeline {
        case .home, .list:
            return identity.handle
        case .local, .federated, .tag:
            return identity.instance?.uri ?? ""
        }
    }

    func refreshIdentity() {
        if identification.service.isAuthorized {
            identification.service.verifyCredentials()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)
            identification.service.refreshLists()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)
            identification.service.refreshFilters()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)

            if identity.preferences.useServerPostingReadingPreferences {
                identification.service.refreshServerPreferences()
                    .assignErrorsToAlertItem(to: \.alertItem, on: self)
                    .sink { _ in }
                    .store(in: &cancellables)
            }
        }

        identification.service.refreshInstance()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }

    func viewModel(timeline: Timeline) -> StatusListViewModel {
        StatusListViewModel(statusListService: identification.service.service(timeline: timeline))
    }
}

public extension TabNavigationViewModel {
    enum Tab: CaseIterable {
        case timelines
        case explore
        case notifications
        case messages
    }
}

extension TabNavigationViewModel.Tab: Identifiable {
    public var id: Self { self }
}
