// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NavigationViewModel: ObservableObject {
    public let identityContext: IdentityContext
    public let navigations: AnyPublisher<Navigation, Never>

    @Published public private(set) var recentIdentities = [Identity]()
    @Published public var presentedNewStatusViewModel: NewStatusViewModel?
    @Published public var presentingSecondaryNavigation = false
    @Published public var alertItem: AlertItem?

    private let navigationsSubject = PassthroughSubject<Navigation, Never>()
    private var cancellables = Set<AnyCancellable>()

    public init(identityContext: IdentityContext) {
        self.identityContext = identityContext
        navigations = navigationsSubject.eraseToAnyPublisher()

        identityContext.$identity
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        identityContext.service.recentIdentitiesPublisher()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$recentIdentities)
    }
}

public extension NavigationViewModel {
    enum Tab: Int, CaseIterable {
        case timelines
        case explore
        case notifications
        case messages
    }

    var tabs: [Tab] {
        if identityContext.identity.authenticated {
            return Tab.allCases
        } else {
            return [.timelines, .explore]
        }
    }

    var timelines: [Timeline] {
        if identityContext.identity.authenticated {
            return Timeline.authenticatedDefaults
        } else {
            return Timeline.unauthenticatedDefaults
        }
    }

    func refreshIdentity() {
        if identityContext.identity.pending {
            identityContext.service.verifyCredentials()
                .collect()
                .map { _ in () }
                .flatMap(identityContext.service.confirmIdentity)
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
        } else if identityContext.identity.authenticated {
            identityContext.service.verifyCredentials()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)
            identityContext.service.refreshLists()
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
            identityContext.service.refreshFilters()
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
            identityContext.service.refreshEmojis()
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
            identityContext.service.refreshAnnouncements()
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)

            if identityContext.identity.preferences.useServerPostingReadingPreferences {
                identityContext.service.refreshServerPreferences()
                    .sink { _ in } receiveValue: { _ in }
                    .store(in: &cancellables)
            }
        }

        identityContext.service.refreshInstance()
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func navigateToProfile(id: Account.Id) {
        presentingSecondaryNavigation = false
        navigationsSubject.send(.profile(identityContext.service.navigationService.profileService(id: id)))
    }

    func navigate(timeline: Timeline) {
        presentingSecondaryNavigation = false
        navigationsSubject.send(
            .collection(identityContext.service.navigationService.timelineService(timeline: timeline)))
    }

    func navigateToFollowerRequests() {
        presentingSecondaryNavigation = false
        navigationsSubject.send(.collection(identityContext.service.service(
                                                accountList: .followRequests,
                                                titleComponents: ["follow-requests"])))
    }

    func navigate(pushNotification: PushNotification) {
        // TODO
    }

    func viewModel(timeline: Timeline) -> CollectionItemsViewModel {
        CollectionItemsViewModel(
            collectionService: identityContext.service.navigationService.timelineService(timeline: timeline),
            identityContext: identityContext)
    }

    func exploreViewModel() -> ExploreViewModel {
        let exploreViewModel = ExploreViewModel(
            service: identityContext.service.exploreService(),
            identityContext: identityContext)

        exploreViewModel.refresh()

        return exploreViewModel
    }

    func notificationsViewModel(excludeTypes: Set<MastodonNotification.NotificationType>) -> CollectionItemsViewModel {
        let viewModel = CollectionItemsViewModel(
            collectionService: identityContext.service.notificationsService(excludeTypes: excludeTypes),
            identityContext: identityContext)

        viewModel.request(maxId: nil, minId: nil, search: nil)

        return viewModel
    }

    func conversationsViewModel() -> CollectionViewModel {
        let conversationsViewModel = CollectionItemsViewModel(
            collectionService: identityContext.service.conversationsService(),
            identityContext: identityContext)

        conversationsViewModel.request(maxId: nil, minId: nil, search: nil)

        return conversationsViewModel
    }
}
