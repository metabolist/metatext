// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NavigationViewModel: ObservableObject {
    public let identification: Identification
    @Published public private(set) var recentIdentities = [Identity]()
    @Published public var timeline: Timeline
    @Published public private(set) var timelinesAndLists: [Timeline]
    @Published public var presentingSecondaryNavigation = false
    @Published public var alertItem: AlertItem?
    public var selectedTab: Tab? = .timelines

    private var cancellables = Set<AnyCancellable>()

    public init(identification: Identification) {
        self.identification = identification
        timeline = identification.identity.authenticated ? .home : .local
        timelinesAndLists = identification.identity.authenticated
            ? Timeline.authenticatedDefaults
            : Timeline.unauthenticatedDefaults

        identification.$identity
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        identification.service.recentIdentitiesPublisher()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$recentIdentities)

        if identification.identity.authenticated {
            identification.service.listsPublisher()
                .map { Timeline.authenticatedDefaults + $0 }
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .assign(to: &$timelinesAndLists)
        }
    }
}

public extension NavigationViewModel {
    var tabs: [Tab] {
        if identification.identity.authenticated {
            return Tab.allCases
        } else {
            return [.timelines, .explore]
        }
    }

    var timelineSubtitle: String {
        switch timeline {
        case .home, .list:
            return identification.identity.handle
        case .local, .federated, .tag, .profile:
            return identification.identity.instance?.uri ?? ""
        }
    }

    func refreshIdentity() {
        if identification.identity.pending {
            identification.service.verifyCredentials()
                .collect()
                .map { _ in () }
                .flatMap(identification.service.confirmIdentity)
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
        } else if identification.identity.authenticated {
            identification.service.verifyCredentials()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)
            identification.service.refreshLists()
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
            identification.service.refreshFilters()
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)

            if identification.identity.preferences.useServerPostingReadingPreferences {
                identification.service.refreshServerPreferences()
                    .sink { _ in } receiveValue: { _ in }
                    .store(in: &cancellables)
            }
        }

        identification.service.refreshInstance()
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func viewModel(timeline: Timeline) -> CollectionItemsViewModel {
        CollectionItemsViewModel(collectionService: identification.service.service(timeline: timeline))
    }
}

public extension NavigationViewModel {
    enum Tab: CaseIterable {
        case timelines
        case explore
        case notifications
        case messages
    }
}

extension NavigationViewModel.Tab: Identifiable {
    public var id: Self { self }
}
