// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NavigationViewModel: ObservableObject {
    public let identification: Identification
    public let timelineNavigations: AnyPublisher<Timeline, Never>

    @Published public private(set) var recentIdentities = [Identity]()
    @Published public var presentingSecondaryNavigation = false
    @Published public var alertItem: AlertItem?

    public lazy var exploreViewModel: ExploreViewModel = {
        let exploreViewModel = ExploreViewModel(
            service: identification.service.exploreService(),
            identification: identification)

        // TODO: initial request

        return exploreViewModel
    }()

    public lazy var notificationsViewModel: CollectionViewModel? = {
        if identification.identity.authenticated {
                let notificationsViewModel = CollectionItemsViewModel(
                    collectionService: identification.service.notificationsService(),
                    identification: identification)

                notificationsViewModel.request(maxId: nil, minId: nil, search: nil)

            return notificationsViewModel
        } else {
            return nil
        }
    }()

    public lazy var conversationsViewModel: CollectionViewModel? = {
        if identification.identity.authenticated {
                let conversationsViewModel = CollectionItemsViewModel(
                    collectionService: identification.service.conversationsService(),
                    identification: identification)

                conversationsViewModel.request(maxId: nil, minId: nil, search: nil)

            return conversationsViewModel
        } else {
            return nil
        }
    }()

    private let timelineNavigationsSubject = PassthroughSubject<Timeline, Never>()
    private var cancellables = Set<AnyCancellable>()

    public init(identification: Identification) {
        self.identification = identification
        timelineNavigations = timelineNavigationsSubject.eraseToAnyPublisher()

        identification.$identity
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        identification.service.recentIdentitiesPublisher()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$recentIdentities)
    }
}

public extension NavigationViewModel {
    enum Tab: CaseIterable {
        case timelines
        case explore
        case notifications
        case messages
    }

    var tabs: [Tab] {
        if identification.identity.authenticated {
            return Tab.allCases
        } else {
            return [.timelines, .explore]
        }
    }

    var timelines: [Timeline] {
        if identification.identity.authenticated {
            return Timeline.authenticatedDefaults
        } else {
            return Timeline.unauthenticatedDefaults
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
            identification.service.refreshEmojis()
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
            identification.service.refreshAnnouncements()
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

    func navigate(timeline: Timeline) {
        presentingSecondaryNavigation = false
        timelineNavigationsSubject.send(timeline)
    }

    func viewModel(timeline: Timeline) -> CollectionItemsViewModel {
        CollectionItemsViewModel(
            collectionService: identification.service.service(timeline: timeline),
            identification: identification)
    }
}
