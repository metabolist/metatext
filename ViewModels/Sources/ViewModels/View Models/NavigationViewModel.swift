// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NavigationViewModel: ObservableObject {
    public let identityContext: IdentityContext
    public let navigations: AnyPublisher<Navigation, Never>

    @Published public private(set) var recentIdentities = [Identity]()
    @Published public private(set) var announcementCount: (total: Int, unread: Int) = (0, 0)
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

        identityContext.service.announcementCountPublisher()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$announcementCount)
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
        presentedNewStatusViewModel = nil
        navigationsSubject.send(.profile(identityContext.service.navigationService.profileService(id: id)))
    }

    func navigate(timeline: Timeline) {
        presentingSecondaryNavigation = false
        presentedNewStatusViewModel = nil
        navigationsSubject.send(
            .collection(identityContext.service.navigationService.timelineService(timeline: timeline)))
    }

    func navigateToFollowerRequests() {
        presentingSecondaryNavigation = false
        presentedNewStatusViewModel = nil
        navigationsSubject.send(.collection(identityContext.service.service(
                                                accountList: .followRequests,
                                                titleComponents: ["follow-requests"])))
    }

    func navigateToMutedUsers() {
        presentingSecondaryNavigation = false
        presentedNewStatusViewModel = nil
        navigationsSubject.send(.collection(identityContext.service.service(
                                                accountList: .mutes,
                                                titleComponents: ["preferences.muted-users"])))
    }

    func navigateToBlockedUsers() {
        presentingSecondaryNavigation = false
        presentedNewStatusViewModel = nil
        navigationsSubject.send(.collection(identityContext.service.service(
                                                accountList: .blocks,
                                                titleComponents: ["preferences.blocked-users"])))
    }

    func navigateToURL(_ url: URL) {
        presentingSecondaryNavigation = false
        presentedNewStatusViewModel = nil
        identityContext.service.navigationService.item(url: url)
            .sink { [weak self] in self?.navigationsSubject.send($0) }
            .store(in: &cancellables)
    }

    func navigate(pushNotification: PushNotification) {
        switch pushNotification.notificationType {
        case .followRequest:
            navigateToFollowerRequests()
        default:
            identityContext.service.notificationService(pushNotification: pushNotification)
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { [weak self] in
                    self?.presentingSecondaryNavigation = false
                    self?.presentedNewStatusViewModel = nil
                    self?.navigationsSubject.send(.notification($0))
                }
                .store(in: &cancellables)
        }
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

        if excludeTypes.isEmpty {
            viewModel.request(maxId: nil, minId: nil, search: nil)
        }

        return viewModel
    }

    func conversationsViewModel() -> CollectionViewModel {
        let conversationsViewModel = CollectionItemsViewModel(
            collectionService: identityContext.service.conversationsService(),
            identityContext: identityContext)

        conversationsViewModel.request(maxId: nil, minId: nil, search: nil)

        return conversationsViewModel
    }

    func announcementsViewModel() -> CollectionViewModel {
        CollectionItemsViewModel(
            collectionService: identityContext.service.announcementsService(),
            identityContext: identityContext)
    }
}
