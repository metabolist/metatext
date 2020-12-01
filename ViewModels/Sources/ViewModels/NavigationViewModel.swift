// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NavigationViewModel: ObservableObject {
    public let identification: Identification
    @Published public private(set) var recentIdentities = [Identity]()
    @Published public var timeline: Timeline {
        didSet {
            timelineViewModel = CollectionItemsViewModel(
                collectionService: identification.service.service(timeline: timeline),
                identification: identification)
        }
    }
    @Published public private(set) var timelinesAndLists: [Timeline]
    @Published public var presentingSecondaryNavigation = false
    @Published public var alertItem: AlertItem?
    public private(set) var timelineViewModel: CollectionItemsViewModel

    public var notificationsViewModel: CollectionViewModel? {
        if identification.identity.authenticated {
            if _notificationsViewModel == nil {
                _notificationsViewModel = CollectionItemsViewModel(
                    collectionService: identification.service.notificationsService(),
                    identification: identification)
                _notificationsViewModel?.request(maxId: nil, minId: nil)
            }

            return _notificationsViewModel
        } else {
            return nil
        }
    }

    public var conversationsViewModel: CollectionViewModel? {
        if identification.identity.authenticated {
            if _conversationsViewModel == nil {
                _conversationsViewModel = CollectionItemsViewModel(
                    collectionService: identification.service.conversationsService(),
                    identification: identification)
                _conversationsViewModel?.request(maxId: nil, minId: nil)
            }

            return _conversationsViewModel
        } else {
            return nil
        }
    }

    private var _notificationsViewModel: CollectionViewModel?
    private var _conversationsViewModel: CollectionViewModel?
    private var cancellables = Set<AnyCancellable>()

    public init(identification: Identification) {
        self.identification = identification
        let timeline: Timeline = identification.identity.authenticated ? .home : .local
        self.timeline = timeline
        timelineViewModel = CollectionItemsViewModel(
            collectionService: identification.service.service(timeline: timeline),
            identification: identification)
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
        case .local, .federated, .tag, .profile, .favorites, .bookmarks:
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
}

public extension NavigationViewModel {
    enum Tab: CaseIterable {
        case timelines
        case explore
        case notifications
        case messages
    }

    func favoritesViewModel() -> CollectionViewModel {
        CollectionItemsViewModel(
            collectionService: identification.service.service(timeline: .favorites),
            identification: identification)
    }

    func bookmarksViewModel() -> CollectionViewModel {
        CollectionItemsViewModel(
            collectionService: identification.service.service(timeline: .bookmarks),
            identification: identification)
    }
}

extension NavigationViewModel.Tab: Identifiable {
    public var id: Self { self }
}
